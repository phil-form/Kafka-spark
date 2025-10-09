import asyncio
import json
from azure.eventhub import EventData
from azure.eventhub.aio import EventHubProducerClient

connectionString = "CONNECTION_STR"
event_hub_name = "HUB_NAME"

async def run():
    producer = EventHubProducerClient.from_connection_string(
        conn_str=connectionString, eventhub_name=event_hub_name
    )
    async with producer:
        event_data_batch = await producer.create_batch()
        with open('data/persons.json') as f:
            data = json.load(f)
            for item in data:
                event_data_batch.add(EventData(json.dumps(item)))
        await producer.send_batch(event_data_batch)

asyncio.run(run())