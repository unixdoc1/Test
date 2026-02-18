const { MongoClient } = require("mongodb");

async function exportSchemaWithFieldCounts() {
  const uri = "mongodb://localhost:27017"; // replace with your connection string
  const client = new MongoClient(uri);

  try {
    await client.connect();
    const db = client.db("myDatabase"); // replace with your database name

    const collections = await db.listCollections().toArray();

    for (const coll of collections) {
      const collection = db.collection(coll.name);

      // Count documents
      const count = await collection.countDocuments();

      // Get indexes
      const indexes = await collection.indexes();

      // Sample documents to infer schema and field counts
      const docs = await collection.find().limit(1000).toArray(); // sample up to 1000 docs
      const schema = {};
      const fieldCounts = {};

      docs.forEach(doc => {
        Object.keys(doc).forEach(key => {
          schema[key] = typeof doc[key];
          fieldCounts[key] = (fieldCounts[key] || 0) + 1;
        });
      });

      const fieldTotal = Object.keys(schema).length;

      // Print collection header
      console.log(`\n### ${coll.name} Collection`);
      console.log(`Document Count: ${count}`);
      console.log(`Field Count: ${fieldTotal}\n`);

      // Print schema table with field instance counts
      console.log("| Field | Type   | Instances |");
      console.log("|-------|--------|-----------|");
      for (const [field, type] of Object.entries(schema)) {
        console.log(`| ${field} | ${type} | ${fieldCounts[field]} |`);
      }

      // Print indexes table
      console.log("\nIndexes:");
      console.log("| Name | Key | Unique |");
      console.log("|------|-----|--------|");
      indexes.forEach(idx => {
        const key = JSON.stringify(idx.key);
        console.log(`| ${idx.name} | ${key} | ${idx.unique ? "Yes" : "No"} |`);
      });
    }

    // Export database-level functions (system.js)
    const functions = await db.collection("system.js").find().toArray();
    if (functions.length > 0) {
      console.log("\n### Database Functions (system.js)\n");
      console.log("| Function Name | Code Snippet |");
      console.log("|---------------|--------------|");
      functions.forEach(fn => {
        console.log(`| ${fn._id} | ${fn.value.code} |`);
      });
    }
  } finally {
    await client.close();
  }
}

exportSchemaWithFieldCounts();
