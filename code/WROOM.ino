#include <Arduino.h>
#include <HardwareSerial.h>

// --- SD Card Includes ---
#include <FS.h>
#include <SD.h>
#include <SPI.h>

// --- WiFi, Time, and MQTT Includes ---
#include <WiFi.h>
#include "time.h"
#include <PubSubClient.h> // Added for MQTT

// --- WiFi Credentials ---
const char* ssid = "Louu";         // <<<--- EDIT
const char* password = "12345689"; // <<<--- EDIT

// --- NTP Configuration (TUNISIA: UTC+1 / CET, No DST) ---
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = 3600;
const int daylightOffset_sec = 0;

// --- MQTT Configuration ---
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_client_id = "esp32-wroom-cam-client198798498";
const char* mqtt_user = "";
const char* mqtt_password = "";
const char* mqtt_topic_meta = "cam/wroom/meta";     // Topic for Timestamp & Filename
// const char* mqtt_topic_image = "cam/wroom/image";   // REMOVED - Topic for raw JPEG image data

// --- SD Card Pin Definition ---
const int SD_CS_PIN = 5;

// --- Pin Definitions ---
const int BUTTON_PIN = 0;
const int CAM_RX_PIN = 16;
const int CAM_TX_PIN = 17;

// --- Serial Ports ---
HardwareSerial CamSerial(2);

// --- Communication Settings ---
const long CAM_BAUD_RATE = 115200;
const long PC_BAUD_RATE = 115200;

// --- Button Debounce ---
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;
int lastButtonState = HIGH;
int buttonState;

// --- State Machine ---
enum State { IDLE, WAITING_FOR_CAM_ACK, EXPECTING_IMG_START, EXPECTING_SIZE, BUFFERING_IMAGE, WAITING_FINAL_OK, ERROR_STATE };
State currentState = IDLE;
const char* stateNames[] = {"IDLE", "WAITING_FOR_CAM_ACK", "EXPECTING_IMG_START", "EXPECTING_SIZE", "BUFFERING_IMAGE", "WAITING_FINAL_OK", "ERROR_STATE"};

// --- Markers from CAM ---
const char* CAM_ACK_SNAP_RECEIVED = "ACK: SNAP Received";
const char* CAM_IMG_START_MARKER = "IMG_START";
const char* CAM_IMG_SIZE_MARKER = "SIZE:";
const char* CAM_IMG_END_MARKER = "IMG_END";
const char* CAM_OK_IMAGE_PROCESSED = "OK: Image Processed";
const char* CAM_ERR_PREFIX = "ERR:";
const char* CAM_OK_FILE_SAVED_PREFIX = "CAM OK: File '";
const char* CAM_FILE_SAVED_SUFFIX = "' saved successfully";

// --- Timeout ---
unsigned long commandStartTime = 0;
const unsigned long commandTimeout = 30000;

// --- Image Buffering & MQTT ---
uint8_t* imageBuffer = nullptr;
size_t expectedImageSize = 0;
size_t receivedImageSize = 0;
bool metadataPublishPending = false; // Flag to indicate metadata is ready to publish (image was buffered)

// --- WROOM SD Logging ---
String lastCapturedFilename = "";
const char* wroomCsvLogFilename = "/cam_log.csv";

// --- Internal Line Buffer ---
char lineBuffer[100];
int lineBufferPos = 0;

// --- MQTT Client ---
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
unsigned long lastMqttReconnectAttempt = 0;

// --- Function Prototypes ---
void handleButton();
void handleCamSerial();
void processLineBuffer();
void resetState(bool error = false);
void changeState(State newState);
void initWiFi();
void syncNtpTime();
void initWroomSDCard();
void saveLogEntryToCsv();
String getFormattedTime();
void setupMQTT();
void reconnectMQTT();
void publishMetadataViaMQTT(); // MODIFIED: Was publishImageViaMQTT
void freeImageBuffer();

// =========================================================================
// SETUP
// =========================================================================
void setup() {
    Serial.begin(PC_BAUD_RATE);
    delay(500);
    Serial.println("\n\n>>> WROOM LOG: Controller + SD Logger + MQTT Metadata Sender <<<"); // Updated Title
    Serial.println("------------------------------------------");

    initWiFi();
    syncNtpTime();
    initWroomSDCard();
    setupMQTT();

    pinMode(BUTTON_PIN, INPUT_PULLUP);
    Serial.println("WROOM LOG: Button Pin Initialized (GPIO0)");

    CamSerial.begin(CAM_BAUD_RATE, SERIAL_8N1, CAM_RX_PIN, CAM_TX_PIN);
    Serial.print("WROOM LOG: Initializing CAM on Serial2..."); Serial.println(" baud...");
    delay(100);
    Serial.println("WROOM LOG: CAM Serial Initialized.");

    Serial.println("------------------------------------------");
    resetState();
}

// =========================================================================
// Initialize WiFi
// =========================================================================
void initWiFi() {
    Serial.print("WROOM LOG: Connecting to WiFi SSID: "); Serial.println(ssid);
    WiFi.begin(ssid, password); unsigned long startAttemptTime = millis();
    while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); if (millis() - startAttemptTime > 15000) { Serial.println("\nERR: WiFi Connection Failed (Timeout)"); return; }}
    Serial.println("\nOK: WiFi Connected!"); Serial.print("IP Address: "); Serial.println(WiFi.localIP());
}

// =========================================================================
// Sync Time via NTP
// =========================================================================
void syncNtpTime() {
    if (WiFi.status() != WL_CONNECTED) { Serial.println("WROOM LOG: WARN: Cannot sync NTP time, WiFi not connected."); return; }
    Serial.println("WROOM LOG: Configuring NTP time..."); configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    Serial.print("WROOM LOG: Waiting for NTP time sync..."); struct tm timeinfo; unsigned long startSyncTime = millis();
    while (!getLocalTime(&timeinfo)) { delay(500); Serial.print("."); if(millis() - startSyncTime > 10000) { Serial.println("\nERR: NTP Time Sync Failed (Timeout)"); return; }}
    Serial.println("\nOK: NTP Time Synchronized"); Serial.print("Current Time: "); Serial.println(getFormattedTime());
}

// =========================================================================
// Initialize WROOM SD Card
// =========================================================================
void initWroomSDCard() {
    Serial.print("WROOM LOG: Initializing WROOM SD Card (CS Pin: "); Serial.print(SD_CS_PIN); Serial.println(")...");
    if (!SD.begin(SD_CS_PIN)) { Serial.println("WROOM LOG: ERR: WROOM SD Card Mount Failed!"); return; }
    uint8_t cardType = SD.cardType(); if (cardType == CARD_NONE) { Serial.println("WROOM LOG: WARN: No SD card found in WROOM module."); return; }
    Serial.print("WROOM LOG: WROOM SD Card Type: "); if (cardType == CARD_MMC) Serial.println("MMC"); else if (cardType == CARD_SD) Serial.println("SDSC"); else if (cardType == CARD_SDHC) Serial.println("SDHC"); else Serial.println("UNKNOWN");
    uint64_t cardSize = SD.cardSize() / (1024 * 1024); Serial.printf("WROOM LOG: WROOM SD Card Size: %lluMB\n", cardSize);
    File file = SD.open(wroomCsvLogFilename); if (!file || file.size() == 0) { if(file) file.close(); Serial.print("WROOM LOG: Creating/Re-creating '"); Serial.print(wroomCsvLogFilename); Serial.println("' with header."); file = SD.open(wroomCsvLogFilename, FILE_WRITE); if (file) { file.println("DateTime,Cam_Filename"); file.close(); Serial.println("WROOM LOG: CSV header written."); } else { Serial.println("WROOM LOG: ERR: Failed to create CSV log file!"); } } else { Serial.print("WROOM LOG: CSV Log file '"); Serial.print(wroomCsvLogFilename); Serial.println("' found."); file.close(); }
}

// =========================================================================
// Setup MQTT Client
// =========================================================================
void setupMQTT() {
  Serial.print("WROOM LOG: Setting up MQTT Broker: "); Serial.println(mqtt_server);
  mqttClient.setServer(mqtt_server, mqtt_port);
}

// =========================================================================
// Reconnect MQTT Client
// =========================================================================
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("WROOM LOG: Attempting MQTT connection...");
    bool result;
    if (strlen(mqtt_user) > 0) {
       result = mqttClient.connect(mqtt_client_id, mqtt_user, mqtt_password);
    } else {
       result = mqttClient.connect(mqtt_client_id);
    }
    if (result) {
      Serial.println(" OK: Connected!");
    } else {
      Serial.print(" ERR failed, rc="); Serial.print(mqttClient.state()); Serial.println(" Try again in 5 seconds");
      delay(5000);
    }
  }
}

// =========================================================================
// LOOP
// =========================================================================
void loop() {
    if (WiFi.status() == WL_CONNECTED && !mqttClient.connected()) {
        unsigned long now = millis();
        if (now - lastMqttReconnectAttempt > 5000) {
            lastMqttReconnectAttempt = now;
            reconnectMQTT();
        }
    }
    if (mqttClient.connected()) {
      mqttClient.loop();
    }

    handleButton();
    handleCamSerial();

    if (currentState != IDLE && currentState != ERROR_STATE) {
        if (millis() - commandStartTime > commandTimeout) {
             Serial.println("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
             Serial.print("WROOM LOG: ERR: Overall timeout waiting for CAM! (State: "); Serial.print(stateNames[currentState]); Serial.println(")");
             Serial.println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            resetState(true);
        }
    }
     if (currentState == ERROR_STATE) {
        delay(2000); Serial.println("WROOM LOG: Exiting ERROR state, returning to IDLE."); changeState(IDLE);
     }
     if(currentState == IDLE) { delay(10); }
}

// =========================================================================
// CHANGE STATE HELPER
// =========================================================================
void changeState(State newState) {
    if (newState != currentState) {
        Serial.print("WROOM LOG: State Change: "); Serial.print(stateNames[currentState]); Serial.print(" -> "); Serial.println(stateNames[newState]);
        currentState = newState;
    }
}

// =========================================================================
// Free Image Buffer Helper
// =========================================================================
void freeImageBuffer() {
    if (imageBuffer != nullptr) {
        Serial.println("WROOM DBG: Freeing image buffer memory.");
        free(imageBuffer);
        imageBuffer = nullptr;
    }
}

// =========================================================================
// RESET STATE
// =========================================================================
void resetState(bool error) {
    Serial.println("--- Resetting State ---");
    if (error) {
        Serial.println("WROOM LOG: Resetting due to an ERROR."); changeState(ERROR_STATE);
    } else {
         Serial.println("WROOM LOG: Image process cycle completed."); changeState(IDLE);
    }
    lineBufferPos = 0; lineBuffer[0] = '\0';
    lastCapturedFilename = "";
    expectedImageSize = 0; receivedImageSize = 0;
    metadataPublishPending = false; // Reset metadata publish flag
    freeImageBuffer();

    if (currentState == IDLE) {
        Serial.println("------------------------------------------");
        Serial.println("WROOM LOG: System IDLE. Ready for button press.");
        Serial.println("------------------------------------------");
    }
}

// =========================================================================
// HANDLE BUTTON PRESS
// =========================================================================
void handleButton() {
    int reading = digitalRead(BUTTON_PIN);
    if (reading != lastButtonState) { lastDebounceTime = millis(); }
    if ((millis() - lastDebounceTime) > debounceDelay) {
        if (reading != buttonState) {
            buttonState = reading;
            if (buttonState == LOW && currentState == IDLE) {
                Serial.println("\n--- Button Pressed ---");
                Serial.println("WROOM LOG: Sending SNAP command to CAM...");
                CamSerial.println("SNAP");
                commandStartTime = millis(); lineBufferPos = 0; expectedImageSize = 0; receivedImageSize = 0;
                lastCapturedFilename = "";
                metadataPublishPending = false;
                freeImageBuffer();
                changeState(WAITING_FOR_CAM_ACK);
            }
        }
    }
    lastButtonState = reading;
}

// =========================================================================
// HANDLE CAM SERIAL COMMUNICATION
// =========================================================================
void handleCamSerial() {
    uint8_t serialBuffer[256];
    size_t bytesRead = 0;

    while (CamSerial.available()) {
        if (currentState == BUFFERING_IMAGE) {
            if (imageBuffer == nullptr) {
                 Serial.println("WROOM LOG: ERR: Image buffer is null in BUFFERING_IMAGE state!");
                 resetState(true); return;
            }
            size_t bytesToRead = min((size_t)CamSerial.available(), sizeof(serialBuffer));
            if (expectedImageSize > 0) {
                 size_t remainingBytes = expectedImageSize - receivedImageSize;
                 bytesToRead = min(bytesToRead, remainingBytes);
            } else {
                 Serial.println("WROOM LOG: ERR: Expected image size is zero in BUFFERING_IMAGE state!");
                 resetState(true); return;
            }
            if(bytesToRead > 0) {
                bytesRead = CamSerial.readBytes(imageBuffer + receivedImageSize, bytesToRead);
            } else { bytesRead = 0; }

            if (bytesRead > 0) {
                receivedImageSize += bytesRead;
                if ((receivedImageSize % (1024 * 8)) < bytesRead) { Serial.print("."); }
                if (receivedImageSize >= expectedImageSize) {
                    Serial.print("\nWROOM LOG: Finished BUFFERING expected ");
                    Serial.print(receivedImageSize); Serial.print("/"); Serial.print(expectedImageSize); Serial.println(" image bytes.");
                    metadataPublishPending = true; // Image buffered, metadata can be published
                    changeState(WAITING_FINAL_OK);
                    commandStartTime = millis();
                    lineBufferPos = 0;
                }
            } else if (bytesRead < 0) {
                 Serial.println("WROOM LOG: ERR: CamSerial.readBytes error during buffering!");
                 resetState(true); return;
             }
        } else {
            int byteReadInt = CamSerial.read();
            if (byteReadInt == -1) continue;
            char receivedChar = (char)byteReadInt;
            Serial.write(receivedChar);
            if (receivedChar != '\r') {
                if (lineBufferPos < sizeof(lineBuffer) - 1) { lineBuffer[lineBufferPos++] = receivedChar; }
                else { Serial.println("WROOM LOG: WARN: Line buffer overflow!"); lineBufferPos = 0; }
            }
            if (receivedChar == '\n') {
                lineBuffer[lineBufferPos] = '\0'; processLineBuffer(); lineBufferPos = 0;
            }
        }
    }
}

// =========================================================================
// PROCESS COMPLETED LINE
// =========================================================================
void processLineBuffer() {
    String lineStr = String(lineBuffer);
    lineStr.trim();
    if (lineStr.length() == 0) return;

    int startIndex = lineStr.indexOf(CAM_OK_FILE_SAVED_PREFIX);
    if (startIndex != -1) {
        int endIndex = lineStr.indexOf(CAM_FILE_SAVED_SUFFIX, startIndex);
        if (endIndex != -1) {
            startIndex += strlen(CAM_OK_FILE_SAVED_PREFIX);
            lastCapturedFilename = lineStr.substring(startIndex, endIndex); lastCapturedFilename.trim();
            Serial.print("\nWROOM LOG (Internal): Captured CAM Filename: ["); Serial.print(lastCapturedFilename); Serial.println("]");
        }
    }
    if (lineStr.startsWith(CAM_ERR_PREFIX)) {
        Serial.print("\nWROOM LOG (Internal): ERR Received from CAM: "); Serial.println(lineStr); resetState(true); return;
    }

    switch (currentState) {
        case WAITING_FOR_CAM_ACK:
            if (lineStr.equals(CAM_ACK_SNAP_RECEIVED)) { Serial.println("\nWROOM LOG (Internal): ACK Received."); changeState(EXPECTING_IMG_START); commandStartTime = millis(); }
            break;
        case EXPECTING_IMG_START:
            if (lineStr.equals(CAM_IMG_START_MARKER)) { Serial.println("\nWROOM LOG (Internal): IMG_START Received."); changeState(EXPECTING_SIZE); commandStartTime = millis(); }
            break;
        case EXPECTING_SIZE:
            if (lineStr.startsWith(CAM_IMG_SIZE_MARKER)) {
                String sizeStr = lineStr.substring(strlen(CAM_IMG_SIZE_MARKER)); sizeStr.trim();
                expectedImageSize = sizeStr.toInt(); receivedImageSize = 0;
                if (expectedImageSize > 0 && expectedImageSize < 200000) {
                    Serial.print("\nWROOM LOG (Internal): SIZE Received: "); Serial.print(expectedImageSize); Serial.println(" bytes.");
                    Serial.println("WROOM LOG (Internal): Allocating image buffer...");
                    freeImageBuffer();
                    imageBuffer = (uint8_t*) malloc(expectedImageSize);
                    if (imageBuffer == nullptr) {
                        Serial.println("WROOM LOG: ERR: Failed to allocate memory for image buffer!");
                        resetState(true);
                    } else {
                         Serial.println("WROOM LOG (Internal): Buffer allocated. Changing state to BUFFERING_IMAGE.");
                         changeState(BUFFERING_IMAGE);
                         commandStartTime = millis();
                    }
                } else {
                    Serial.print("WROOM LOG (Internal): ERR: Invalid image size received: "); Serial.println(expectedImageSize);
                    resetState(true);
                }
            }
            break;
         case WAITING_FINAL_OK:
             if (lineStr.startsWith(CAM_OK_IMAGE_PROCESSED) || lineStr.startsWith("CAM: Ready")) {
                 Serial.print("\nWROOM LOG (Internal): CAM final confirmation RX. Checking conditions for MQTT/CSV...");

                 Serial.printf("  DBG: metadataPublishPending=%s, filenameLen=%d, bufferNotNull=%s, sizeMatch=%s\n",
                               (metadataPublishPending ? "true" : "false"),
                               lastCapturedFilename.length(),
                               (imageBuffer != nullptr ? "true" : "false"),
                               (receivedImageSize == expectedImageSize ? "true" : "false"));

                 if (metadataPublishPending && lastCapturedFilename.length() > 0 && imageBuffer != nullptr && receivedImageSize == expectedImageSize) {
                      Serial.println(" Conditions met. Saving CSV & Publishing MQTT Metadata...");
                      saveLogEntryToCsv();
                      publishMetadataViaMQTT(); // MODIFIED call
                 } else {
                      Serial.println(" Conditions NOT met. Skipping CSV & MQTT Metadata.");
                      if (!metadataPublishPending) Serial.println("   Reason: Metadata Publish flag not set.");
                      if (lastCapturedFilename.length() == 0) Serial.println("   Reason: Filename missing.");
                      if (imageBuffer == nullptr) Serial.println("   Reason: Buffer is null (image not buffered).");
                      if (receivedImageSize != expectedImageSize) Serial.printf("   Reason: Size mismatch (%d vs %d).\n", receivedImageSize, expectedImageSize);
                      freeImageBuffer(); // Still free buffer if it was allocated but conditions not met for publish
                 }
                 metadataPublishPending = false;
                 resetState(false);
             }
             break;
        case IDLE: case BUFFERING_IMAGE: case ERROR_STATE: break;
        default:
             Serial.print("\nWROOM LOG (Internal): WARN: Unexpected text line in state "); Serial.print(stateNames[currentState]); Serial.print(": "); Serial.println(lineStr);
            break;
    }
}

// =========================================================================
// MODIFIED: Publish ONLY Metadata via MQTT
// =========================================================================
void publishMetadataViaMQTT() { // Renamed function
    if (WiFi.status() != WL_CONNECTED || !mqttClient.connected()) {
        Serial.println("WROOM LOG: ERR: Cannot publish MQTT Metadata - Not connected.");
        freeImageBuffer(); // Free buffer if we can't publish (image data is not sent, but buffer might hold it)
        return;
    }
    // Image buffer check is no longer strictly necessary if we only send metadata,
    // but metadataPublishPending ensures the image was *intended* to be processed.
    if (!metadataPublishPending) {
        Serial.println("WROOM LOG: WARN: Attempting to publish metadata, but metadataPublishPending flag is false.");
        // Continue to publish metadata if filename is available, but log this.
    }
     if (lastCapturedFilename.length() == 0) {
        Serial.println("WROOM LOG: WARN: Publishing MQTT metadata without filename (capture/SD save failed?).");
        // Decide if you want to publish anyway or return
        // return; // Uncomment if filename is mandatory for metadata
    }

    String currentTime = getFormattedTime();
    String metaPayload = currentTime + "," + lastCapturedFilename;

    Serial.print("WROOM LOG: Publishing Metadata to ["); Serial.print(mqtt_topic_meta); Serial.print("]: "); Serial.println(metaPayload);
    bool metaSent = mqttClient.publish(mqtt_topic_meta, metaPayload.c_str());

    if (!metaSent) {
        Serial.println("WROOM LOG: ERR: Failed to publish metadata!");
    } else {
        Serial.println("WROOM LOG: Metadata published successfully.");
    }

    // --- CRITICAL: Free the image buffer as we are done with it ---
    // Even if we didn't send the image data itself via MQTT,
    // the buffer was used to receive the image from the CAM.
    freeImageBuffer();
}

// =========================================================================
// Helper function to get formatted time string
// =========================================================================
String getFormattedTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    if(WiFi.status() != WL_CONNECTED) { Serial.println("ERR: Failed to obtain time - WiFi Disconnected!"); }
    else { Serial.println("ERR: Failed to obtain time (is NTP sync lost?)"); }
    return "Time Unknown";
  }
  char timeStringBuff[50]; strftime(timeStringBuff, sizeof(timeStringBuff), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(timeStringBuff);
}

// =========================================================================
// SAVE LOG ENTRY TO WROOM's SD CARD CSV
// =========================================================================
void saveLogEntryToCsv() {
    Serial.println("WROOM DBG: Entering saveLogEntryToCsv().");
    if (lastCapturedFilename.length() == 0) {
        Serial.println("WROOM LOG: WARN: Cannot save to CSV - missing filename.");
        Serial.println("WROOM DBG: Exiting saveLogEntryToCsv() due to missing filename.");
        return;
    }
    Serial.print("WROOM DBG: Filename check PASSED. Filename: [");
    Serial.print(lastCapturedFilename); Serial.println("]");

    String formattedTime = getFormattedTime();
    Serial.print("WROOM DBG: Time check. Formatted Time: [");
    Serial.print(formattedTime); Serial.println("]");
    if (formattedTime.equals("Time Unknown")) {
         Serial.println("WROOM LOG: WARN: Cannot save to CSV - time is not synchronized.");
         Serial.println("WROOM DBG: Exiting saveLogEntryToCsv() due to unknown time.");
         return;
    }
    Serial.println("WROOM DBG: Time check PASSED.");

    Serial.print("WROOM LOG: Attempting to append to CSV (Local SD): ");
    Serial.print(wroomCsvLogFilename); Serial.print(" -> ");
    Serial.print(formattedTime); Serial.print(","); Serial.println(lastCapturedFilename);

    Serial.println("WROOM DBG: Calling SD.open() for append...");
    File file = SD.open(wroomCsvLogFilename, FILE_APPEND);
    if (!file) {
        Serial.println("WROOM DBG: SD.open() FAILED!");
        if (SD.cardType() != CARD_NONE) {
             Serial.println("WROOM LOG: ERR: Failed to open CSV file for appending! (Check WROOM SD Card)");
        } else {
             Serial.println("WROOM LOG: ERR: Failed to open CSV file - SD Card not detected/mounted during setup.");
        }
        Serial.println("WROOM DBG: Exiting saveLogEntryToCsv() due to file open failure.");
        return;
    }
    Serial.println("WROOM DBG: SD.open() SUCCEEDED.");

    Serial.println("WROOM DBG: Calling file.print() / println()...");
    bool write_ok = false;
    if (file.print(formattedTime)) {
        if(file.print(",")) {
            if(file.println(lastCapturedFilename)) {
                write_ok = true;
            }
        }
    }

    if(write_ok) {
        Serial.println("WROOM LOG: Successfully appended data to CSV.");
        Serial.println("WROOM DBG: file.print/println chain SUCCEEDED.");
    } else {
        Serial.println("WROOM LOG: ERR: Failed to write data to CSV file!");
        Serial.println("WROOM DBG: file.print/println chain FAILED.");
    }

    Serial.println("WROOM DBG: Attempting file.close()...");
    file.close();
    Serial.println("WROOM DBG: file.close() called.");
    Serial.println("WROOM DBG: Exiting saveLogEntryToCsv() normally.");
}