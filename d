// === Schema + Data Types for ALL collections (Robo 3T safe) ===
// Prints: Collection name, then each field and the set of BSON types seen.
// NOTE: MongoDB is schemaless; this is inferred from sampled documents.

var SAMPLE_SIZE = 20000; // change to 0 to scan entire collection (not recommended)

var collections = db.getCollectionNames();

for (var i = 0; i < collections.length; i++) {
    var collName = collections[i];

    // skip system collections
    if (collName.indexOf("system.") === 0) {
        continue;
    }

    print("\n==================================================");
    print("Collection: " + collName);
    print("==================================================");

    var pipeline = [];

    // Sample docs to reduce load (recommended). If SAMPLE_SIZE=0, skip sampling.
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
        print("ERROR processing collection: " + collName);
        print(e);
    }
}
