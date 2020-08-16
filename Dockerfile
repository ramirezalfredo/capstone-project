FROM python:3.8.2-alpine3.11

# Create a working directory
WORKDIR /app

# Copy source code to working directory
COPY . hello.py /app/

# Install packages from requirements.txt
# hadolint ignore=DL3013
RUN pip install --upgrade pip &&\
    pip install --trusted-host pypi.python.org -r requirements.txt

# Expose port 80
EXPOSE 5000

# Run app.py at container launch
CMD ["python", "hello.py"]
