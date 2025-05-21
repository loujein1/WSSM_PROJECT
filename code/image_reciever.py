from flask import Flask, request, send_from_directory, jsonify
import os
from datetime import datetime
import logging
import requests # Still needed

# Configure basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

app = Flask(__name__)

# --- Configuration ---
UPLOAD_FOLDER = 'uploads' # Flask might still save a copy, or you can disable it
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# --- Node-RED Image Forwarding Configuration ---
NODE_RED_IP_ADDRESS = "127.0.0.1" # Or "localhost" - for Node-RED on the SAME machine as Flask
NODE_RED_PORT = "8000"            # Default Node-RED port (change if you've modified Node-RED's port)
NODE_RED_IMAGE_ENDPOINT = "/nodered_image_receiver" # Path you will set in Node-RED http in node
NODE_RED_FORWARD_URL = f"http://{NODE_RED_IP_ADDRESS}:{NODE_RED_PORT}{NODE_RED_IMAGE_ENDPOINT}"
ENABLE_NODE_RED_FORWARDING = True
# --- End Node-RED Configuration ---

@app.route('/upload_image', methods=['POST'])
def upload_image_route():
    if request.method == 'POST':
        logging.info(f"Received request to /upload_image from {request.remote_addr}")
        logging.info(f"  Content-Type: {request.content_type}")
        logging.info(f"  Content-Length: {request.content_length} bytes")

        filename_header = request.headers.get('X-Filename')
        timestamp_header = request.headers.get('X-Timestamp')
        original_content_type = request.content_type # Get the original content type

        if filename_header:
            logging.info(f"  X-Filename Header: {filename_header}")
        else:
            logging.info("  X-Filename Header: Not provided")
        # ... (rest of your header logging)

        try:
            image_data = request.get_data()
            if not image_data:
                logging.error("No image data received in POST request body.")
                return jsonify({"status": "error", "message": "No image data received"}), 400

            # --- Optional: Save a copy on Flask server ---
            # You can choose to still save the image on the Flask server, or skip this
            # if Node-RED is the primary recipient for storage.
            filename_to_save_on_flask = "temp_esp_upload.jpg" # Example, or use your existing logic
            if filename_header:
                 base, ext = os.path.splitext(os.path.basename(filename_header))
                 safe_base = "".join(c if c.isalnum() or c in ('_','-') else '_' for c in base)
                 filename_to_save_on_flask = f"{safe_base}{ext if ext else '.jpg'}"

            filepath_flask = os.path.join(app.config['UPLOAD_FOLDER'], filename_to_save_on_flask)
            with open(filepath_flask, 'wb') as f:
                f.write(image_data)
            logging.info(f"Image temporarily saved to Flask server: {filepath_flask}")
            # --- End Optional Save ---


            # --- Forward the image data to Node-RED ---
            if ENABLE_NODE_RED_FORWARDING:
                headers_for_nodered = {}
                if original_content_type:
                    headers_for_nodered['Content-Type'] = original_content_type
                if filename_header:
                    headers_for_nodered['X-Filename'] = filename_header # Forward original filename
                if timestamp_header:
                    headers_for_nodered['X-Timestamp'] = timestamp_header # Forward original timestamp
                # Add any other custom headers you want to forward

                try:
                    logging.info(f"Attempting to forward image data to Node-RED: {NODE_RED_FORWARD_URL}")
                    # Send the raw image_data as the body
                    response_from_nodered = requests.post(
                        NODE_RED_FORWARD_URL,
                        data=image_data, # Send raw bytes
                        headers=headers_for_nodered,
                        timeout=10 # Increased timeout for potentially larger data
                    )

                    if 200 <= response_from_nodered.status_code < 300:
                        logging.info(f"Successfully forwarded image to Node-RED. Status: {response_from_nodered.status_code}")
                        # Optionally log response_from_nodered.text or .json()
                    else:
                        logging.error(f"Failed to forward image to Node-RED. Status: {response_from_nodered.status_code}, Response: {response_from_nodered.text}")
                except requests.exceptions.RequestException as e_req:
                    logging.error(f"Error forwarding image to Node-RED: {e_req}")
            # --- End Forwarding to Node-RED ---

            # Return success to ESP-CAM
            return jsonify({
                "status": "success",
                "message": "Image received by Flask and processed.",
                "forwarded_to_nodered": ENABLE_NODE_RED_FORWARDING,
                # "original_filename": filename_header if filename_header else "N/A" # Optional: include in response
            }), 200

        except Exception as e:
            logging.error(f"Error processing or saving/forwarding image: {e}", exc_info=True)
            return jsonify({"status": "error", "message": f"Server error: {e}"}), 500
    else:
        return jsonify({"status": "error", "message": "Method Not Allowed. Only POST requests are accepted."}), 405


# --- Optional: Route to view uploaded files (from Flask's storage) ---
@app.route('/uploads/<path:filename>')
def serve_uploaded_file(filename):
    # ... (same as before) ...
    logging.info(f"Request to view uploaded file: {filename}")
    try:
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)
    except FileNotFoundError:
        logging.error(f"File not found in uploads: {filename}")
        return jsonify({"status": "error", "message": "File not found"}), 404

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok", "message": "Server is healthy"}), 200

if __name__ == '__main__':
    host = '0.0.0.0'
    port = 5000
    logging.info(f"Starting Flask server on http://{host}:{port}")
    logging.info(f"Node-RED Image Forwarding URL set to: {NODE_RED_FORWARD_URL if ENABLE_NODE_RED_FORWARDING else 'Disabled'}")
    app.run(host=host, port=port, debug=True)