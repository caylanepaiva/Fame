Class {
	#name : 'FMJSONSeparatedCompactPrinter',
	#superclass : 'FMJSONPrinter',
	#category : 'Fame-ImportExport-Traits',
	#package : 'Fame-ImportExport',
	#tag : 'Traits'
}

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> beginEntity: name [

    stream
        nextPut: ${;
        nextPutAll: '"FM3":"';
        nextPutAll: name;
        nextPutAll: '",'
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> beginProperty: name [

    stream
        nextPut: $";
        nextPutAll: name;
        nextPut: $";
        nextPut: $:
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> beginRelationEntity [
	stream nextPut: ${
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> crTabs [
    "Compact JSON: no line breaks, no tabs."

    ^ self
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> endDocument [

    stream nextPut: $]
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> endEntities [

    stream nextPut: $]
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> endEntity: name [

    stream nextPut: $}
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> endRelationEntity [
	stream nextPut: $}
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> endRelations [

    stream nextPut: $]
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> referenceName: name [

    stream
        nextPut: ${;
        nextPutAll: '"ref":';
        nextPut: $";
        nextPutAll: name;
        nextPut: $";
        nextPut: $}
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> referenceNumber: index [

    stream
        nextPut: ${;
        nextPutAll: '"ref":';
        print: index;
        nextPut: $}
]

{ #category : 'private' }
FMJSONSeparatedCompactPrinter >> serial: index [

    stream
        nextPutAll: '"id":';
        print: index
]
