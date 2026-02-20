# How to Access and Manage AWS DocumentDB Cluster Using MongoDB Compass

This document provides instructions for connecting to an AWS DocumentDB cluster using MongoDB Compass and creating databases and collections through the user interface. It also includes commonly used MongoDB shell commands available within the Compass embedded shell.

## 1. Prerequisites

Retrieve the following information from your AWS DocumentDB setup:

- Cluster endpoint (refer to your AWS Management Console for the region-specific endpoint under DocumentDB cluster details)
- Port (default: 27017)
- Database username and password (contact your database administrator for credentials)
- Download the AWS RDS global CA certificate from the following link: https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

Ensure the security group for DocumentDB allows inbound traffic from your client machine on port 27017.

## 2. Install MongoDB Compass

Download and install MongoDB Compass from:
https://www.mongodb.com/try/download/compass

## 3. Download and Store the CA Certificate

### Download the Certificate

Navigate to the following URL and download the certificate file:
https://truststore.pki.rds.amazonaws.com/global/global-bundle. pem

### Store the Certificate Locally

Save the certificate file in a secure, accessible location on your machine. Recommended storage locations include:

**Windows:**
```
C:\Users\YourUsername\Documents\certs\global-bundle.pem
C:\certs\global-bundle.pem
```

**macOS:**
```
/Users/YourUsername/Documents/certs/global-bundle. pem
/Users/YourUsername/.aws/certs/global-bundle.pem
```

**Linux:**
```
/home/yourusername/certs/global-bundle.pem
/home/yourusername/.aws/certs/global-bundle.pem
```

Ensure the file has appropriate read permissions and note the full file path as you will need it for the connection string.

## 4. Prepare the Connection String

Use the following connection string format. Replace `DB_USERNAME` with your database username, `PASSWORD` with your actual password, `YOUR_CLUSTER_ENDPOINT` with your region-specific cluster endpoint as found in the AWS Console, and `PATH_TO_PEM` with the full path to your saved certificate file.

```
mongodb://DB_USERNAME:PASSWORD@YOUR_CLUSTER_ENDPOINT:27017/?tls=true&tlsCAFile=PATH_TO_PEM&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

### Example Connection String

Certificate stored at: `C:\certs\global-bundle.pem`

```
mongodb://DB_USERNAME:PASSWORD@xxxx-xxx-x-xxxx-docdb.cluster-************.us-east-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=C:\certs\global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false
```

**Important Notes:**

- Contact your database administrator to obtain the correct username and password
- Use the exact file path where you saved the certificate on your system
- On Windows, use backslashes in the path
- On macOS and Linux, use forward slashes in the path
- Replace `YourUsername` with your actual system username
- Ensure there are no spaces in the file path

## 5. Connect with MongoDB Compass

1. Open MongoDB Compass.
2. Click **New Connection**.
3. Paste your connection string in the provided field. Replace `DB_USERNAME`, `PASSWORD`, `YOUR_CLUSTER_ENDPOINT`, and `PATH_TO_PEM` as appropriate.
4. Click **Connect**.

Alternatively, use the **Advanced Connection** form to manually specify:

- **Hostname** (your cluster endpoint)
- **Port** (27017)
- **Username** (obtain from your database administrator)
- **Password** (your password)
- **Authentication Database** (admin)
- **Replica Set Name** (rs0)
- **Read Preference** (secondaryPreferred)
- **TLS/SSL** (enabled)
- **CA Certificate** (browse and select the full path to global-bundle.pem)
- **Additional Options** (retryWrites=false)

## 6. Create a Database and Collection Using the UI

### Creating a New Database

1. Once connected, locate the **Create Database** button in the left sidebar.
2. Enter your desired database name in the **Database Name** field.
3. Enter a name for the first collection (a database must have at least one collection to be created).
4. Click **Create Database**.

### Adding Additional Collections

1. Select your database from the left sidebar.
2. Click the **Create Collection** button. 
3. Enter the desired collection name.
4. Click **Create Collection**.

## 7. Add Documents Using the UI

1. Click on the collection where you want to add data.
2. Click the **Insert Document** button.
3. Enter your document in JSON format or use the form view to add fields and values.
4. Click **Insert** to save the document.

## 8. Using the Mongo Shell within MongoDB Compass

MongoDB Compass includes an embedded MongoDB shell for executing commands directly. 

### Steps to Open the Mongo Shell

1. After connecting, locate the **MongoSH** or **Open Mongo Shell** button at the bottom left of the MongoDB Compass window or in the top menu bar.
2. Click to open the shell interface.

### Common MongoDB Shell Commands

```javascript
use my_database
show dbs
show collections

db.createCollection("my_collection")
db.my_collection.drop()

db.my_collection.insertOne({ name: "John", age: 30 })
db.my_collection.insertMany([{ name: "Alice" }, { name: "Bob" }])

db.my_collection.find()
db.my_collection.findOne({ name: "Alice" })

db.my_collection.updateOne({ name: "Alice" }, { $set: { age: 26 } })
db.my_collection.updateMany({ city: "Seattle" }, { $set: { state: "WA" } })

db.my_collection.deleteOne({ name: "Bob" })
db.my_collection.deleteMany({ age: { $lt: 30 } })

db.my_collection.countDocuments()
db.my_collection.createIndex({ name: 1 })
db.my_collection.getIndexes()

db.stats()
db.my_collection.stats()
db.dropDatabase()
```

## 9. Troubleshooting

- Verify credentials, cluster endpoint, and CA certificate path are correct.
- Ensure the certificate file path uses the correct format for your operating system (backslashes for Windows, forward slashes for macOS/Linux).
- Confirm the certificate file exists at the specified path and has read permissions.
- Ensure your IP address is authorized in the DocumentDB security group.
- Confirm network access on port 27017.
- Use a compatible version of MongoDB Compass (AWS DocumentDB supports MongoDB 3.6, 4.0, or 5.0 wire protocol).
- Contact your database administrator if you encounter authentication issues.

## 10. References

- **Amazon DocumentDB:  Connect using MongoDB Compass**
  https://docs.aws.amazon.com/documentdb/latest/developerguide/connect-using-mongodb-compass.html

- **MongoDB Compass UI Guide**
  https://www.mongodb.com/docs/compass/current/
