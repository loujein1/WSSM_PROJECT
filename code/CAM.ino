// --- Sketch for ESP32-CAM (Camera Peripheral) ---
// ** UPDATED: Saves image to CAM's onboard SD Card,
// **          Sends Image via HTTP POST to Server,
// **          AND Sends Data/Markers over Serial to WROOM **
// ** WARNING: Requires STABLE 5V power supply for the CAM module! **
// ** SD Card must be inserted in CAM module and formatted as FAT32 **

#include "esp_camera.h"
#include <WiFi.h>         // For WiFi connection needed for HTTP
#include "HTTPClient.h"   // For sending image via HTTP
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "driver/rtc_io.h"

// --- SD Card Includes ---
#include "FS.h"       // File System related functions
#include "SD_MMC.h"   // SD Card library using MMC interface (for built-in slot)

// --- WiFi Credentials for ESP32-CAM ---
const char* ssid_cam = "Louu";         // <<<--- EDIT ESP32-CAM's WiFi SSID
const char* password_cam = "12345689"; // <<<--- EDIT ESP32-CAM's WiFi Password

// --- HTTP Server Configuration (for ESP32-CAM to send image to) ---
// This should be your PC's IP address on the "Louu" network
const char* httpServerAddress_cam = "http://192.168.43.246:5000/upload_image"; // <<<--- EDIT PC SERVER IP

// --- Define Communication Baud Rate (to WROOM) ---
const long SERIAL_BAUD_RATE = 115200; // Must match WROOM-32's CAM_BAUD_RATE

// --- AI-THINKER ESP32-CAM PINOUT ---
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26 // SDA
#define SIOC_GPIO_NUM     27 // SCL
#define Y9_GPIO_NUM       35 // D7
#define Y8_GPIO_NUM       34 // D6
#define Y7_GPIO_NUM       39 // D5
#define Y6_GPIO_NUM       36 // D4
#define Y5_GPIO_NUM       21 // D3
#define Y4_GPIO_NUM       19 // D2
#define Y3_GPIO_NUM       18 // D1
#define Y2_GPIO_NUM        5 // D0
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// --- Markers for Image Data Transfer (to WROOM via Serial) ---
const char* IMG_START_MARKER = "IMG_START";
const char* IMG_SIZE_MARKER = "SIZE:";
const char* IMG_END_MARKER = "IMG_END";

// --- SD Card File Naming ---
int pictureNumber = 0; // Counter for image filenames on CAM's SD card

// Function prototype for HTTP send
void sendImageViaHTTP(camera_fb_t * fb, const String& filename_on_sd);

// =========================================================================
// SETUP
// =========================================================================
void setup() {
    WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); // Disable brownout detector

    Serial.begin(SERIAL_BAUD_RATE); // This is for communication with WROOM
    // Serial.setDebugOutput(true); // Set true for more verbose logs if needed
    delay(1000);
    Serial.println("CAM_LOG: ESP32-CAM Dual Send Mode (HTTP & Serial)");

    // --- Initialize WiFi ---
    Serial.print("CAM_LOG: Connecting to WiFi: ");
    Serial.println(ssid_cam);
    WiFi.begin(ssid_cam, password_cam);
    unsigned long startAttemptTime = millis();
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
        if (millis() - startAttemptTime > 20000) { // 20-second timeout
            Serial.println("\nCAM_ERR: WiFi Connection Failed (Timeout)");
            // Decide how to handle: continue without HTTP, or halt/restart
            // For now, we'll let it continue, HTTP will fail.
            break;
        }
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nCAM_OK: WiFi Connected!");
        Serial.print("CAM_LOG: IP Address: ");
        Serial.println(WiFi.localIP());
    }
    // --- End WiFi Init ---


    // --- Initialize SD Card (using SD_MMC for built-in slot) ---
    Serial.println("CAM_LOG: Initializing SD Card...");
    if (!SD_MMC.begin("/sdcard", true)) {
        Serial.println("CAM_ERR: SD Card Mount Failed! Check card/format/slot.");
    } else {
        uint8_t cardType = SD_MMC.cardType();
        if (cardType == CARD_NONE) {
            Serial.println("CAM_WARN: No SD card attached");
        } else {
            Serial.print("CAM_OK: SD Card Type detected.");
            uint64_t cardSize = SD_MMC.cardSize() / (1024 * 1024);
            Serial.printf(" Size: %lluMB\n", cardSize);
        }
    }
    // --- End SD Init ---

    Serial.println("CAM_LOG: Send 'SNAP' or 'PING' via Serial (from WROOM).");

    // --- Camera Configuration ---
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM; config.pin_d1 = Y3_GPIO_NUM; config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM; config.pin_d4 = Y6_GPIO_NUM; config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM; config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM; config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM; config.pin_href = HREF_GPIO_NUM;
    config.pin_sscb_sda = SIOD_GPIO_NUM; config.pin_sscb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM; config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size = FRAMESIZE_SVGA; // (800x600) - Good for quality
    // config.frame_size = FRAMESIZE_VGA; // (640x480) - Faster, smaller files
    // config.frame_size = FRAMESIZE_CIF; // (352x288) - Even smaller
    config.jpeg_quality = 12;           // 10-12 is good. Lower value = higher quality, larger file.
    config.fb_count = 1;                // Use 1 frame buffer if PSRAM is limited, 2 for higher frame rates if available
    #if CONFIG_IDF_TARGET_ESP32S3
        config.fb_location = CAMERA_FB_IN_PSRAM; // For S3, use PSRAM for frame buffer
        config.grab_mode = CAMERA_GRAB_LATEST;   // S3 specific grab mode
    #else // Original ESP32
        // fb_location is not used, grab_mode default is fine.
    #endif


    // --- Initialize Camera ---
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("CAM_ERR: Camera init failed with error 0x%x\n", err);
        Serial.println("CAM_ERR: Check connections/pins. Power/PSRAM needed for SVGA/UXGA.");
        Serial.println("CAM_LOG: Restarting in 5 seconds...");
        delay(5000);
        ESP.restart();
    } else {
        Serial.println("CAM_OK: Camera Initialized Successfully");
    }
}

// =========================================================================
// LOOP
// =========================================================================
void loop() {
    // Serial is used for commands from WROOM
    if (Serial.available()) {
        String command = Serial.readStringUntil('\n');
        command.trim();

        // Echo command back FOR WROOM (not for PC debug here)
        // Serial.print("CAM_DBG: Rx Cmd: ["); Serial.print(command); Serial.println("]");

        if (command.equalsIgnoreCase("SNAP")) {
            Serial.println("ACK: SNAP Received"); // Acknowledge WROOM
            takePictureProcessAndSendAll(); // Call the combined function
        } else if (command.equalsIgnoreCase("PING")) {
           Serial.println("ACK: PONG"); // Acknowledge WROOM
        } else {
           // Don't send error for unknown, WROOM might send other things
           // Serial.print("CAM ERR: Unknown command: "); Serial.println(command);
        }
    }
    delay(10); // Small delay to prevent busy-looping
}

// =========================================================================
// TAKE PICTURE, SAVE TO SD, SEND VIA HTTP, AND SEND DATA/MARKERS TO WROOM
// =========================================================================
void takePictureProcessAndSendAll() {
    camera_fb_t * fb = NULL;
    String filename_on_sd = ""; // Store the actual filename saved to SD

    // --- 1. Take Picture ---
    // Serial.println("CAM_LOG: Taking picture..."); // Log for PC debug if uncommented
    fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("CAM_ERR: Camera capture failed"); // Log for PC debug
        Serial.println("ERR: Capture Failed");           // Error marker for WROOM
        return;
    }
    // Serial.printf("CAM_LOG: Picture taken! Size: %u bytes, Format: %d\n", fb->len, fb->format);


    // --- 2. Attempt to Save Image to CAM's SD Card ---
    if (SD_MMC.cardType() != CARD_NONE) {
        char path[32];
        sprintf(path, "/picture_%03d.jpg", pictureNumber); // Use %03d for leading zeros, e.g., picture_001.jpg
        filename_on_sd = String(path);

        // Serial.printf("CAM_LOG: Saving file to SD: %s\n", path);
        fs::FS &fs = SD_MMC;
        File file = fs.open(path, FILE_WRITE);

        if (!file) {
            // Serial.printf("CAM_ERR: Failed to open file '%s' for writing\n", path);
            Serial.println("ERR: SD File Open Failed"); // Error marker for WROOM
            filename_on_sd = ""; // Clear filename if save failed
        } else {
            size_t bytesWritten = file.write(fb->buf, fb->len);
            file.close();
            if (bytesWritten == fb->len) {
                // THIS IS THE LINE THE WROOM EXPECTS FOR FILENAME
                Serial.printf("CAM OK: File '%s' saved successfully\n", path);
                pictureNumber++;
            } else {
                // Serial.printf("CAM_ERR: File '%s' write failed! Wrote %u/%u bytes.\n", path, bytesWritten, fb->len);
                Serial.println("ERR: SD File Write Failed"); // Error marker for WROOM
                filename_on_sd = ""; // Clear filename if save failed
            }
        }
    } else {
        // Serial.println("CAM_WARN: No SD card for save.");
        Serial.println("ERR: SD Card Not Found For Save"); // Error marker for WROOM
    }
    // --- End SD Save Attempt ---


    // --- 3. Send Image Data via HTTP to PC Server ---
    if (WiFi.status() == WL_CONNECTED) {
        // Use filename_on_sd (which might be empty if SD save failed)
        // or generate a default one if filename_on_sd is empty.
        String http_filename = filename_on_sd;
        if (http_filename.startsWith("/")) { // Remove leading slash for HTTP header
            http_filename = http_filename.substring(1);
        }
        if (http_filename.isEmpty()) {
            http_filename = "cam_capture.jpg"; // Default if SD failed or no SD
        }
        sendImageViaHTTP(fb, http_filename);
    } else {
        // Serial.println("CAM_WARN: WiFi not connected, skipping HTTP send.");
        // No specific error marker needed for WROOM for HTTP failure,
        // as WROOM's primary image source is Serial from CAM.
    }
    // --- End HTTP Send ---


    // --- 4. Send Image Data and Markers over Serial to WROOM ---
    // This happens regardless of SD or HTTP success, as WROOM expects it.
    Serial.println(IMG_START_MARKER);
    Serial.print(IMG_SIZE_MARKER);
    Serial.println(fb->len);
    Serial.flush(); // Ensure text markers are sent before binary data
    Serial.write(fb->buf, fb->len); // Send the raw byte buffer
    Serial.flush(); // Ensure all data is sent before the end marker
    Serial.println(); // Extra newline for cleaner separation on WROOM
    Serial.println(IMG_END_MARKER);
    // --- End Serial Data Send to WROOM ---


    // --- 5. Return Frame Buffer ---
    esp_camera_fb_return(fb); // IMPORTANT: Release frame buffer AFTER all uses


    // --- 6. Final Status Messages for WROOM ---
    Serial.println("OK: Image Processed"); // Generic success for WROOM
    // Serial.println("CAM_LOG: Ready for next command."); // PC Debug log
}

// =========================================================================
// SEND IMAGE VIA HTTP POST (Helper Function for ESP32-CAM)
// =========================================================================
void sendImageViaHTTP(camera_fb_t * fb, const String& filename_for_header) {
    if (!fb || fb->len == 0) {
        // Serial.println("CAM_HTTP_ERR: No frame buffer data to send.");
        return;
    }
    if (WiFi.status() != WL_CONNECTED) {
        // Serial.println("CAM_HTTP_ERR: WiFi not connected.");
        return;
    }

    HTTPClient http;
    WiFiClient clientForHttp; // Good practice to declare one

    // Serial.print("CAM_HTTP_LOG: Connecting to server: "); Serial.println(httpServerAddress_cam);
    if (!http.begin(clientForHttp, httpServerAddress_cam)) {
        // Serial.println("CAM_HTTP_ERR: HTTPClient.begin() failed!");
        return;
    }

    http.addHeader("Content-Type", "image/jpeg");
    if (!filename_for_header.isEmpty()) {
        http.addHeader("X-Filename", filename_for_header);
    }
    // You could add a timestamp from the CAM here if you implement NTP on the CAM
    // http.addHeader("X-Timestamp", getCamTimestamp());

    // Serial.print("CAM_HTTP_LOG: Sending POST request (");
    // Serial.print(fb->len); Serial.println(" bytes)...");

    int httpCode = http.POST(fb->buf, fb->len);

    if (httpCode > 0) {
        // Serial.printf("CAM_HTTP_LOG: POST response code: %d\n", httpCode);
        // String payload = http.getString(); // Potentially large, use with caution
        // Serial.print("CAM_HTTP_LOG: Server response: "); Serial.println(payload);
        if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_CREATED) {
            // Serial.println("CAM_HTTP_LOG: Image uploaded successfully.");
        } else {
            // Serial.printf("CAM_HTTP_WARN: Upload returned HTTP status %d\n", httpCode);
        }
    } else {
        // Serial.printf("CAM_HTTP_ERR: POST failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
}