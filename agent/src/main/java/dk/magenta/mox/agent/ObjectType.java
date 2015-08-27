package dk.magenta.mox.agent;

import org.json.JSONException;
import org.json.JSONObject;

import javax.naming.OperationNotSupportedException;
import java.io.*;
import java.util.*;
import java.util.concurrent.Future;

/**
 * Created by lars on 30-07-15.
 */

public class ObjectType {
    private String name;
    private HashMap<String, Operation> operations;

    public enum Method {
        GET,
        POST,
        PUT,
        DELETE,
        HEAD
    }

    public class Operation {
        private String name;
        public Method method;
        public String path;
        public Operation(String name) {
            this.name = name;
        }
    }

    private static final String COMMAND_CREATE = "create";
    private static final String COMMAND_UPDATE = "update";
    private static final String COMMAND_PASSIVATE = "passivate";
    private static final String COMMAND_DELETE = "delete";

    public ObjectType(String name) {
        this.name = name;
        this.operations = new HashMap<String, Operation>();
    }

    private Operation addOperation(String name) {
        Operation operation = new Operation(name);
        this.operations.put(name, operation);
        return operation;
    }

    public Operation addOperation(String name, Method method, String path) {
        if (name != null) {
            Operation operation = this.addOperation(name);
            operation.method = method;
            operation.path = path;
            return operation;
        }
        return null;
    }

    public Operation getOperation(String name) {
        return this.getOperation(name, false);
    }

    public Operation getOperation(String name, boolean createIfMissing) {
        Operation operation = this.operations.get(name);
        if (operation == null && createIfMissing) {
            return this.addOperation(name);
        }
        return operation;
    }

    public static Map<String,ObjectType> load(String propertiesFileName) throws IOException {
        return load(new File(propertiesFileName));
    }

    public static Map<String,ObjectType> load(File propertiesFile) throws IOException {
        Properties properties = new Properties();
        properties.load(new FileInputStream(propertiesFile));
        return load(properties);
    }

    public static Map<String,ObjectType> load(Properties properties) {
        HashMap<String, ObjectType> objectTypes = new HashMap<String, ObjectType>();
        for (String key : properties.stringPropertyNames()) {
            String[] path = key.split("\\.");
            if (path.length >= 4 && path[0].equals("type")) {
                String name = path[1];
                ObjectType objectType = objectTypes.get(name);
                if (objectType == null) {
                    objectType = new ObjectType(name);
                    objectTypes.put(name, objectType);
                }
                String operationName = path[2];
                Operation operation = objectType.getOperation(operationName, true);
                String attributeName = path[3].trim();
                String attributeValue = properties.getProperty(key);
                if (attributeName.equals("method")) {
                    try {
                        operation.method = Method.valueOf(attributeValue);
                    } catch (IllegalArgumentException e) {
                        String[] strings = new String[Method.values().length];
                        int i=0;
                        for (Method m : Method.values()) {
                            strings[i++] = m.toString();
                        }
                        System.err.println("Error loading properties: method '"+attributeName+"' is not recognized. Recognized methods are: " + String.join(", ", strings));
                    }
                } else if (attributeName.equals("path")) {
                    operation.path = attributeValue;
                }
            }
        }
        String[] neededOperations = {COMMAND_CREATE, COMMAND_UPDATE, COMMAND_PASSIVATE, COMMAND_DELETE};
        for (ObjectType objectType : objectTypes.values()) {
            for (String operation : neededOperations) {
                if (!objectType.operations.containsKey(operation)) {
                    System.err.println("Warning: Object type "+objectType.name+" does not contain the "+operation+" operation. Calls to methods using that operation will fail.");
                }
            }
        }
        return objectTypes;
    }

    public String getName() {
        return name;
    }





    public Future<String> create(MessageSender sender, JSONObject data) throws IOException, OperationNotSupportedException {
        return this.create(sender, data, null);
    }

    public Future<String> create(MessageSender sender, JSONObject data, String authorization) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(COMMAND_CREATE)) {
            return this.sendCommand(sender, COMMAND_CREATE, null, data, authorization);
        } else {
            throw new OperationNotSupportedException("Operation "+ COMMAND_CREATE +" is not defined for Object type "+this.name);
        }
    }


    public Future<String> update(MessageSender sender, UUID uuid, JSONObject data) throws IOException, OperationNotSupportedException {
        return this.update(sender, uuid, data, null);
    }

    public Future<String> update(MessageSender sender, UUID uuid, JSONObject data, String authorization) throws IOException, OperationNotSupportedException {
            if (this.operations.containsKey(COMMAND_UPDATE)) {
            return this.sendCommand(sender, COMMAND_UPDATE, uuid, data, authorization);
        } else {
            throw new OperationNotSupportedException("Operation "+ COMMAND_UPDATE +" is not defined for Object type "+this.name);
        }
    }


    public Future<String> passivate(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        return this.passivate(sender, uuid, note, null);
    }

    public Future<String> passivate(MessageSender sender, UUID uuid, String note, String authorization) throws IOException, OperationNotSupportedException {
            if (this.operations.containsKey(COMMAND_PASSIVATE)) {
            JSONObject data = new JSONObject();
            if (note == null) {
                note = "";
            }
            try {
                data.put("Note", note);
                data.put("livscyklus", "Passiv");
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return this.sendCommand(sender, COMMAND_PASSIVATE, uuid, data, authorization);
        } else {
            throw new OperationNotSupportedException("Operation "+ COMMAND_PASSIVATE +" is not defined for Object type "+this.name);
        }
    }

    public Future<String> delete(MessageSender sender, UUID uuid, String note) throws IOException, OperationNotSupportedException {
        return this.delete(sender, uuid, note, null);
    }

    public Future<String> delete(MessageSender sender, UUID uuid, String note, String authorization) throws IOException, OperationNotSupportedException {
        if (this.operations.containsKey(COMMAND_DELETE)) {
            JSONObject data = new JSONObject();
            if (note == null) {
                note = "";
            }
            try {
                data.put("Note", note);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return this.sendCommand(sender, COMMAND_DELETE, uuid, data, authorization);
        } else {
            throw new OperationNotSupportedException("Operation "+ COMMAND_DELETE +" is not defined for Object type "+this.name);
        }
    }





    public Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data) throws IOException {
        return this.sendCommand(sender, operationName, uuid, data, null);
    }


    public Future<String> sendCommand(MessageSender sender, String operationName, UUID uuid, JSONObject data, String authorization) throws IOException {
        HashMap<String, Object> headers = new HashMap<String, Object>();
        headers.put(MessageInterface.HEADER_OBJECTTYPE, this.name);
        headers.put(MessageInterface.HEADER_OPERATION, operationName);
        if (uuid != null) {
            headers.put(MessageInterface.HEADER_MESSAGEID, uuid.toString());
        }
        if (authorization != null) {
            headers.put(MessageInterface.HEADER_AUTHORIZATION, authorization);
        }
        try {
            return sender.sendJSON(headers, data);
        } catch (InterruptedException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static String capitalize(String s) {
        return s.substring(0, 1).toUpperCase() + s.substring(1).toLowerCase();
    }

}
