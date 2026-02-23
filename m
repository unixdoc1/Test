var dbName = db.getName();

/* ---------- FORMATTER ---------- */

function pad(str, len){
  str = String(str);
  return str + " ".repeat(Math.max(len - str.length, 0));
}

function printRow(cols, widths){
  var line = "";
  for(var i=0;i<cols.length;i++){
    line += pad(cols[i], widths[i]) + " | ";
  }
  print(line);
}

function printHeader(title){
  print("\n==================== " + title + " ====================\n");
}

/* ---------- FIELD ANALYZER ---------- */

function analyzeDoc(doc, prefix, stats){
  Object.keys(doc).forEach(function(k){
    var path = prefix ? prefix + "." + k : k;
    var val = doc[k];

    var type = Array.isArray(val) ? "array" :
               val === null ? "null" :
               (val && val._bsontype) ? val._bsontype :
               typeof val;

    if(!stats[path]){
      stats[path] = {count:0, types:{}};
    }

    stats[path].count++;
    stats[path].types[type] = true;

    if(type==="object" && val!==null && !Array.isArray(val)){
      analyzeDoc(val, path, stats);
    }
  });
}

/* ---------- COLLECTION SUMMARY ---------- */

printHeader("COLLECTIONS");

var collWidths = [25,15,10];
printRow(["Collection","Documents","Indexes"], collWidths);

db.getCollectionNames().forEach(function(name){
  if(name.startsWith("system.")) return;
  var c = db.getCollection(name);
  printRow([name, c.count(), c.getIndexes().length], collWidths);
});

/* ---------- FIELD TABLE ---------- */

printHeader("FIELDS");

var fieldWidths = [20,40,12,30];
printRow(["Collection","Field","Occurrences","Types"], fieldWidths);

db.getCollectionNames().forEach(function(collName){

  if(collName.startsWith("system.")) return;

  var coll = db.getCollection(collName);
  var stats = {};

  coll.find().forEach(function(doc){
    analyzeDoc(doc,"",stats);
  });

  Object.keys(stats).forEach(function(field){
    var s = stats[field];
    printRow([
      collName,
      field,
      s.count,
      Object.keys(s.types).join(",")
    ], fieldWidths);
  });
});

/* ---------- INDEX TABLE ---------- */

printHeader("INDEXES");

var idxWidths = [20,25,35,8];
printRow(["Collection","Index Name","Fields","Unique"], idxWidths);

db.getCollectionNames().forEach(function(collName){

  if(collName.startsWith("system.")) return;

  db.getCollection(collName).getIndexes().forEach(function(idx){

    var fields = Object.keys(idx.key)
      .map(k=>k+":"+idx.key[k])
      .join(",");

    printRow([
      collName,
      idx.name,
      fields,
      idx.unique ? "yes" : "no"
    ], idxWidths);

  });
});

/* ---------- STORED FUNCTIONS ---------- */

printHeader("FUNCTIONS");

if(db.system.js.find().count() === 0){
  print("No stored functions found.");
}else{

  var fnWidths = [25,80];
  printRow(["Name","Code"], fnWidths);

  db.system.js.find().forEach(function(f){
    printRow([f._id, f.value.toString()], fnWidths);
  });
}
