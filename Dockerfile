# 1. Use an official Python runtime as a parent image
FROM python:3.10-slim

# 2. Install system dependencies for OpenCV and Face Recognition
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. Set the working directory
WORKDIR /app

# 4. Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of the application
COPY . .

# 6. Run the warmup script to pre-download AI models
RUN python warmup.py

# 7. Expose the port uvicorn runs on
EXPOSE 8000

# 8. Command to run the application
CMD ["uvicorn", "server.py:app", "--host", "0.0.0.0", "--port", "8000"]
