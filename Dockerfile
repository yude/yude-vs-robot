FROM python:3.9.10-bullseye AS builder
WORKDIR /app

# Install Python dependencies
ADD ./app/requirements.txt /app/
RUN apt update; apt -y install libfreetype-dev libjpeg-dev && \
    /usr/local/bin/python -m pip install --upgrade pip && \
    pip install --prefer-binary -r requirements.txt

FROM python:3.9.10-bullseye AS runner
WORKDIR /app

# Setup timezone & install cron
RUN apt update; apt -y install tzdata libfreetype-dev libjpeg-dev busybox-static && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apt -y purge tzdata && \
    apt -y autoremove

# Copy dependencies from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Add application to the image
ADD ./app/main.py /app/

# Add script to crontab
RUN mkdir -p /var/spool/cron/crontabs/ && \
    echo '0 */12 * * * cd /app; /usr/local/bin/python main.py' >> /var/spool/cron/crontabs/root

ENTRYPOINT ["busybox", "crond", "-f", "-L", "/dev/stderr"]