# Stage 1: Build the website
FROM debian:bullseye AS builder

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git jq nodejs npm cmark-gfm && \
    rm -rf /var/lib/apt/lists/*

# Install chroma for syntax highlighting
RUN curl -sSL https://github.com/alecthomas/chroma/releases/download/v2.23.1/chroma-2.23.1-linux-amd64.tar.gz | tar xz -C /usr/local/bin chroma

# Set the working directory
WORKDIR /website

# Copy the entire project into the container
COPY . .

# Ensure the build script is executable
RUN chmod +x ./gen

# Run the build script to generate the website
RUN ./gen

# Stage 2: Serve the website with Nginx
FROM nginx:alpine

# Remove default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy the generated build files from the builder stage
COPY --from=builder --chown=nginx:nginx /website/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
