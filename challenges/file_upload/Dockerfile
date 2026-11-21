FROM python:3.12-slim
RUN useradd -m -s /usr/sbin/nologin web && mkdir -p /srv/private /srv/uploads /proof && chown web:web /srv/uploads /proof
COPY app.py /srv/app.py
USER web
EXPOSE 8080
WORKDIR /srv
CMD ["python", "/srv/app.py"]
