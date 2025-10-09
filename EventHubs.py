import asyncio
import json

from azure.eventhub import EventData
from azure.eventhub.aio import EventHubProducerClient

EVENT_HUB_CONNECTION_STR = "CONNECTION_STRING"
EVENT_HUB_NAME = "EVENT_HUB_NAME"

async def run():
    # Create a producer client to send messages to the event hub.
    # Specify a connection string to your event hubs namespace and
    # the event hub name.
    producer = EventHubProducerClient.from_connection_string(
        conn_str=EVENT_HUB_CONNECTION_STR, eventhub_name=EVENT_HUB_NAME
    )
    async with producer:
        print("Creating producer and batch...")
        # Create a batch.
        event_data_batch = await producer.create_batch()

        print("Loading data from JSON file...")
        # import json file data/data.json
        with open('data/persons.json') as f:
            data = json.load(f)
            for item in data:
                print("Sending item:", item)
                event_data_batch.add(EventData(json.dumps(item)))

        # Send the batch of events to the event hub.
        print("Sending batch of events...")
        await producer.send_batch(event_data_batch)

print("Starting to send events...")
asyncio.run(run())
print("Finished sending events.")