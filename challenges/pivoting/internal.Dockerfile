FROM python:3.12-slim
RUN useradd -m lab && mkdir -p /proof && chown lab:lab /proof
COPY internal.py /opt/internal.py
USER lab
CMD ["python", "/opt/internal.py"]
