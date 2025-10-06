FROM bitnamilegacy/spark:3.4.1

USER root

# --- Dépendances système ---
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-dev openjdk-17-jdk curl git vim build-essential sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# --- Librairies Python principales ---
RUN pip3 install --no-cache-dir \
    jupyter jupyterlab ipykernel pyspark==3.4.1 kafka-python psycopg2-binary pandas matplotlib seaborn sqlite-utils

# --- Kernel Jupyter ---
RUN python3 -m ipykernel install --name "spark-env" --display-name "Python (Spark)"

# --- Répertoire de travail ---
WORKDIR /work
EXPOSE 8888

# --- JARs Spark-Kafka + PostgreSQL + SQLite ---
ADD https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.4.1/spark-sql-kafka-0-10_2.12-3.4.1.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.6.1/kafka-clients-3.6.1.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/apache/kafka/kafka_2.12/3.6.1/kafka_2.12-3.6.1.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/apache/kafka/kafka-streams/3.6.1/kafka-streams-3.6.1.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.17/scala-library-2.12.17.jar /opt/bitnami/spark/jars/
ADD https://jdbc.postgresql.org/download/postgresql-42.6.0.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.11.1/commons-pool2-2.11.1.jar /opt/bitnami/spark/jars/
ADD https://repo1.maven.org/maven2/org/apache/spark/spark-token-provider-kafka-0-10_2.12/3.4.1/spark-token-provider-kafka-0-10_2.12-3.4.1.jar /opt/bitnami/spark/jars/
# --- Driver JDBC SQLite ---
ADD https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.45.1.0/sqlite-jdbc-3.45.1.0.jar /opt/bitnami/spark/jars/

# --- Vérification et installation conditionnelle de requirements.txt ---
COPY . /work
RUN if [ -f "requirements.txt" ]; then \
      echo "Installation des dépendances supplémentaires depuis requirements.txt..." && \
      pip3 install --no-cache-dir -r requirements.txt; \
    else \
      echo "Aucun requirements.txt trouvé, passage..."; \
    fi

# --- Commande par défaut : lancement de JupyterLab ---
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--NotebookApp.token=''"]
