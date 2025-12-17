#!/bin/bash
set -e
set -u

echo "════════════════════════════════════════════"
echo "  Docker Verification Test"
echo "════════════════════════════════════════════"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running"
    exit 1
fi

echo "Building Docker test image..."
docker build -t ubuntu-nix-test -f Dockerfile.test .

echo ""
echo "Running tests in Docker container..."
echo "This may take 10-15 minutes for first run (downloading and building packages)..."
echo ""

# Run test container
# Note: We don't use --privileged as it's not needed for our tests
docker run --rm \
    -e TERM=xterm-256color \
    ubuntu-nix-test

echo ""
echo "════════════════════════════════════════════"
echo "✅ Docker verification completed successfully!"
echo "════════════════════════════════════════════"
echo ""
echo "All tests passed in Docker environment."
echo "Your configuration is ready for deployment to Ubuntu 24.04 servers."
