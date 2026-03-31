# 1. Use an official Python runtime (Bullseye is more stable for AI)
FROM python:3.10-slim-bullseye

# 2. Install ONLY essential build tools (required for AI libraries)
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. Set the working directory
WORKDIR /app

# 4. Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of the application
COPY . .

# 6. Run the warmup script to pre-download AI models
RUN python warmup.py

# 7. Expose the port uvicorn runs on
EXPOSE 8000

# 8. Start the application using dynamic port
CMD uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}
