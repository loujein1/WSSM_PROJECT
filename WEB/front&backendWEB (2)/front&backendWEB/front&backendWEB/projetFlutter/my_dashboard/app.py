import matplotlib
matplotlib.use('Agg')
import flask
from flask import Flask, request, jsonify, send_file
import torch
from torchvision import transforms
from PIL import Image
import io
import logging
from torch.serialization import add_safe_globals
from flask_cors import CORS
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from torch.nn import LSTM
from sklearn.preprocessing import MinMaxScaler
import os
from torch.nn import LSTM, Linear


# Allowlist these classes explicitly
add_safe_globals([LSTM, Linear])


# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)
# Configure CORS to allow requests from any origin during development
CORS(app, resources={r"/*": {"origins": "*", "supports_credentials": True}})

# Define your LSTM model class here (copy it from your Colab notebook)
class LSTMModel(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.lstm = torch.nn.LSTM(input_size=1, hidden_size=130, num_layers=2, batch_first=True)
        self.fc = torch.nn.Linear(130, 1)

    def forward(self, x):
        out, _ = self.lstm(x)
        out = self.fc(out[:, -1, :])
        return out

# Add the model class to safe globals
add_safe_globals([LSTMModel])
add_safe_globals([LSTM])

# Load model with error handling
try:
    logger.info("Loading model...")
    # Set these to the values you used during training!
    input_size = 2  # number of features (meter reading, diff)
    hidden_size = 128  # example value, replace with your actual value
    num_layers = 2     # example value, replace with your actual value
    num_classes = 1    # example value, replace with your actual value

    model = torch.load('water_model.pt', map_location=torch.device('cpu'))
    model.eval()
    logger.info("Model loaded successfully!")
except Exception as e:
    logger.error(f"Error loading model: {str(e)}")
    raise

def transform_image(image_bytes):
    try:
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
        ])
        image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        return transform(image).unsqueeze(0)
    except Exception as e:
        logger.error(f"Error transforming image: {str(e)}")
        raise

@app.route('/predict', methods=['POST'])
def predict():
    try:
        logger.info("Received prediction request")
        if 'image' not in request.files:
            logger.error("No image in request")
            return jsonify({'error': 'No image uploaded'}), 400
        
        file = request.files['image']
        logger.info(f"Received file: {file.filename}")
        
        img_bytes = file.read()
        logger.info("Image read successfully")
        
        tensor = transform_image(img_bytes)
        logger.info("Image transformed successfully")
        
        with torch.no_grad():
            outputs = model(tensor)
            _, predicted = outputs.max(1)
            prediction = int(predicted.item())
            logger.info(f"Prediction made: {prediction}")
        
        return jsonify({
            'prediction': prediction,
            'status': 'success',
            'message': 'Prediction completed successfully'
        })
    
    except Exception as e:
        logger.error(f"Error during prediction: {str(e)}")
        return jsonify({
            'error': str(e),
            'status': 'error',
            'message': 'An error occurred during prediction'
        }), 500

@app.route('/predict-default', methods=['GET'])
def predict_default():
    try:
        df = pd.read_csv('water_data.csv')
        scaler = MinMaxScaler()
        scaled = scaler.fit_transform(df[["diff"]])
        df["scaled_reading"] = scaled

        WINDOW_SIZE = 24
        input_sequence = df["scaled_reading"].values[:WINDOW_SIZE].reshape(1, WINDOW_SIZE, 1).astype(np.float32)
        tensor = torch.tensor(input_sequence)

        with torch.no_grad():
            output = model(tensor)
            scaled_pred = output[0].detach().numpy()
            # Inverse transform to get the real value
            real_pred = scaler.inverse_transform([scaled_pred])[0][0]
        return jsonify({
            'prediction': float(real_pred),
            'status': 'success',
            'message': 'Prediction completed successfully'
        })
    except Exception as e:
        print("Error during prediction:", e)
        return jsonify({
            'error': str(e),
            'status': 'error',
            'message': 'An error occurred during prediction'
        }), 500

@app.route('/test', methods=['GET'])
def test():
    return jsonify({'status': 'API is running'})

@app.route('/water-usage', methods=['GET'])
def water_usage():
    df = pd.read_csv('water_data.csv')
    data = df.to_dict(orient='records')
    return jsonify(data)

@app.route('/water-usage/summary', methods=['GET'])
def water_usage_summary():
    df = pd.read_csv('water_data.csv')
    total_usage = df['diff'].sum()
    avg_usage = df['diff'].mean()
    return jsonify({
        'total_usage': total_usage,
        'avg_usage': avg_usage
    })

@app.route('/water-usage/by-date', methods=['GET'])
def water_usage_by_date():
    date = request.args.get('date')  # Expecting 'YYYY-MM-DD'
    df = pd.read_csv('water_data.csv')
    # Convert 'datetime' to pandas datetime and extract date in 'YYYY-MM-DD' format
    df['date'] = pd.to_datetime(df['datetime'], dayfirst=True).dt.strftime('%Y-%m-%d')
    usage = df[df['date'] == date]['diff'].sum()
    return jsonify({'date': date, 'usage': usage})

@app.route('/generate-charts', methods=['GET'])
def generate_charts():
    print("Generate charts endpoint called")
    try:
        print("Starting chart generation...")

        # Clear any existing plots
        plt.clf()
        plt.close('all')

        print("Reading CSV file...")
        df = pd.read_csv('water_data.csv')
        print(f"CSV loaded successfully. Shape: {df.shape}")

        print("Scaling data...")
        scaler = MinMaxScaler()
        scaled = scaler.fit_transform(df[["diff"]])
        df["scaled_reading"] = scaled
        print("Data scaled successfully")

        print("Detecting anomalies...")
        threshold = 3 * df["diff"].std()
        anomalies = df[(df["diff"].abs() > threshold)]
        print(f"Found {len(anomalies)} anomalies.")

        print("Creating figure...")
        fig = plt.figure(figsize=(15, 5))
        plt.plot(df["datetime"], df["scaled_reading"], label="Scaled Meter Reading")
        plt.scatter(anomalies["datetime"], anomalies["scaled_reading"], color='red', marker='x', s=100, label='Anomaly (Big Change)')
        plt.title("Hourly Water Consumption - Anomaly Detection")
        plt.xlabel("Time")
        plt.ylabel("Scaled Meter Reading")
        plt.legend()
        plt.tight_layout()
        print("Figure created successfully")

        BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        chart_path = os.path.join(BASE_DIR, 'chart1.png')
        print(f"Attempting to save chart to: {chart_path}")

        fig.savefig(chart_path, format='png', dpi=100, bbox_inches='tight')
        plt.close(fig)
        print(f"Chart saved at: {chart_path}")

        return jsonify({'status': 'success', 'message': 'Charts generated'})
    except Exception as e:
        print("Error during chart generation:", str(e))
        import traceback
        print(traceback.format_exc())
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/chart/<n>')
def get_chart(n):
    try:
        BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        chart_path = os.path.join(BASE_DIR, f'{n}.png')
        print(f"Serving chart from: {chart_path}")
        print(f"Chart exists: {os.path.exists(chart_path)}")
        
        if not os.path.exists(chart_path):
            print(f"Chart not found at {chart_path}, attempting to generate it now")
            generate_charts()
            if not os.path.exists(chart_path):
                return jsonify({'error': f'Chart {n}.png not found even after generation attempt'}), 404
        
        # Add cache control headers to prevent caching
        response = send_file(chart_path, mimetype='image/png')
        response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response
    except Exception as e:
        print(f"Error serving chart: {str(e)}")
        return jsonify({'error': str(e)}), 404

@app.route('/available-charts', methods=['GET'])
def available_charts():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    chart_files = [f for f in os.listdir(BASE_DIR) if f.endswith('.png') and 'chart' in f]
    chart_paths = [os.path.splitext(f)[0] for f in chart_files]
    print(f"Found chart paths: {chart_paths}")
    return jsonify(chart_paths)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
