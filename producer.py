import json
from kafka.admin import KafkaAdminClient, NewTopic
from kafka import KafkaProducer

kafka_server = 'kafka:9092'
topic = 'persons'

admin = KafkaAdminClient(bootstrap_servers=kafka_server)
topic_list = admin.list_topics()
if topic not in topic_list:
    new_topic = NewTopic(name=topic, num_partitions=1, replication_factor=1)
    admin.create_topics(new_topics=[new_topic])

producer = KafkaProducer(bootstrap_servers=[kafka_server], value_serializer=lambda v: json.dumps(v).encode('utf-8'))

with open('data/persons.json', 'r') as file:
    persons = json.load(file)
    for person in persons:
        producer.send(topic, value=person)

    producer.flush()

producer.close()