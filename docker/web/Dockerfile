FROM ubuntu
EXPOSE 5000
COPY . /app
WORKDIR /app

RUN apt-get update -y \
    && apt install -y python3-pip \
    && apt install -y python3-venv \
    && apt-get install -y locales \
    && python3 -m venv ubuntu_env \
    && pip install -r requirements.txt \
    && pip install uwsgi \
    && chmod +x run.sh \
    # использование русского языка в запросах
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LC_MESSAGES=POSIX \
    && locale-gen ru_RU.UTF-8 \
    && apt-get install -y language-pack-ru
ENV LANGUAGE ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
ENTRYPOINT ["bash", "./run.sh"]