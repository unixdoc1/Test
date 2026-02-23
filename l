var dbName = db.getName();
var output = {
  database: dbName,
  collections: {},
  functions: []
};

/* ---------- SCHEMA ANALYZER ---------- */

function analyzeDoc(doc, prefix, stats){
  Object.keys(doc).forEach(function(k){
    var path = prefix ? prefix + "." + k : k;
    var val = doc[k];
    var type = Array.isArray(val) ? "array" :
               val === null ? "null" :
               typeof val;

    if(!stats[path]){
      stats[path] = { count:0, types:{} };
    }

    stats[path].count++;
    stats[path].types[type] = true;

    if(type === "object" && val !== null && !Array.isArray(val)){
      analyzeDoc(val, path, stats);
    }
  });
}

/* ---------- COLLECTION LOOP ---------- */

db.getCollectionNames().forEach(function(collName){

  if(collName.startsWith("system.")) return;

  var coll = db.getCollection(collName);
  var stats = {};

  coll.find().forEach(function(doc){
    analyzeDoc(doc, "", stats);
  });

  /* convert type objects → arrays */
  Object.keys(stats).forEach(function(f){
    stats[f].types = Object.keys(stats[f].types);
  });

  output.collections[collName] = {
    document_count: coll.count(),
    indexes: coll.getIndexes(),
    fields: stats
  };
});

/* ---------- STORED FUNCTIONS ---------- */

if(db.system.js.find().count() > 0){
  db.system.js.find().forEach(function(f){
    output.functions.push({
      name: f._id,
      code: f.value.toString()
    });
  });
}

/* ---------- PRINT RESULT ---------- */

printjson(output);
