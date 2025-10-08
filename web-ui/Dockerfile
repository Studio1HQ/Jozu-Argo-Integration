FROM nginx:alpine

# Copy the static website files
COPY ./html /usr/share/nginx/html

# Copy custom nginx configuration if needed
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]