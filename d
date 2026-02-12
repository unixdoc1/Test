// ===============================
// CONFIGURATION
// ===============================
var SAMPLE_SIZE = 20000;   // set to 0 to scan entire collection (not recommended)

// ===============================
// START
// ===============================
var collections = db.getCollectionNames();

for (var i = 0; i < collections.length; i++) {

    var collName = collections[i];

    // Skip system collections
    if (collName.indexOf("system.") === 0) {
        continue;
    }

    print("\n==================================================");
    print("Collection: " + collName);
    print("==================================================");

    // ===============================
    // 1️⃣ PRINT INDEX INFORMATION
    // ===============================
    print("\n--- Indexes ---");

    try {
        var indexes = db.getCollection(collName).getIndexes();

        for (var j = 0; j < indexes.length; j++) {
            var idx = indexes[j];

            print("Index Name: " + idx.name);
            print("  Keys: " + tojson(idx.key));

            if (idx.unique) print("  Unique: true");
            if (idx.sparse) print("  Sparse: true");
            if (idx.expireAfterSeconds) print("  TTL: " + idx.expireAfterSeconds + " seconds");
            if (idx.partialFilterExpression) print("  Partial Index: " + tojson(idx.partialFilterExpression));

            print("-----------------------------------");
        }
    } catch (e) {
        print("Error retrieving indexes: " + e);
    }

    // ===============================
    // 2️⃣ PRINT SCHEMA (FIELDS + TYPES)
    // ===============================
    print("\n--- Schema (Top-Level Fields) ---");

    var pipeline = [];

    if (SAMPLE_SIZE && SAMPLE_SIZE > 0) {
        pipeline.push({ $sample: { size: SAMPLE_SIZE } });
    }

    pipeline.push(
        { $project: { fields: { $objectToArray: "$$ROOT" } } },
        { $unwind: "$fields" },
        {
            $group: {
                _id: "$fields.k",
                types: { $addToSet: { $type: "$fields.v" } }
            }
        },
        { $sort: { _id: 1 } }
    );

    try {
        var cursor = db.getCollection(collName).aggregate(pipeline, { allowDiskUse: true });

        while (cursor.hasNext()) {
            var r = cursor.next();
            print("Field: " + r._id + " | Types: " + r.types.join(", "));
        }
    } catch (e) {
        print("Error analyzing schema: " + e);
    }
}
