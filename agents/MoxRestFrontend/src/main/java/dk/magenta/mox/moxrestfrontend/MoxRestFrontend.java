package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.MoxAgent;
import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.TimeoutException;

public class MoxRestFrontend extends MoxAgent {

    private String restInterface = null;
    private Map<String, ObjectType> objectTypes;

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxAgent agent = new MoxAgent(args);
        agent.run();
    }

    public MoxRestFrontend(String[] args) {
        super(args);
        this.loadObjectTypes();
    }

    private void loadObjectTypes() {
        this.objectTypes = ObjectType.load(this.getProperties());
    }

    public void run() {
        AmqpDefinition amqpDefinition = this.getAmqpDefinition();
        System.out.println("Listening for messages from RabbitMQ service at " + amqpDefinition + ", queue name '" + amqpDefinition + "'");
        System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + this.restInterface);
        MessageReceiver messageReceiver = null;
        try {
            messageReceiver = this.createMessageReceiver();
            messageReceiver.run(new RestMessageHandler(this.restInterface, this.objectTypes));
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        }
        if (messageReceiver != null) {
            messageReceiver.close();
        }

    }
}