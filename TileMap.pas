{$mode objfpc}
{$modeswitch advancedrecords}

unit TileMap;
interface
uses
	CWString, Contnrs, VectorMath, GeometryTypes, SysUtils, DOM, FGL;

{$define INTERFACE}
{$include include/Utils.inc}
{$undef INTERFACE}

const
	kUndefinedProperty = '';
	kInvalidGID = -1;

const
	kTileLayerOrientationOrthogonal = 0;
	kTileLayerOrientationIsometric = 1;

type
	GIDInt = LongInt;

type
	TTMXTileImage = record
		source: ansistring;
		fullPath: ansistring;
		size: TVec2;
	end;

type
	TTMXTileSet = class;

	TTMXNode = class
		public
			function GetProperty (name: string): variant;
			property Properties[name: string]: variant read GetProperty; default;
		protected
			destructor Destroy; override;
			procedure HandleLoad (info: TMap); virtual;
		private
			m_properties: TMap;
			constructor Create (info: TMap); overload;
			procedure AddProperty (name: string; value: variant);
			procedure AddPropertyTag (info: TMap);
		public
			name: string;
			visible: boolean;
	end;

	TTMXObject = class (TTMXNode)
		public	
			tileID: GIDInt;
			frame: TRect;
			tileset: TTMXTileSet;
		protected
			procedure HandleLoad (info: TMap); override;
		private
			constructor Create (inTileset: TTMXTileSet; info: TMap);
	end;
	TTMXObjectList = specialize TFPGObjectList<TTMXObject>;

	TTMXObjectGroup = class (TTMXNode)
		private
			m_objects: TTMXObjectList;
			function GetObject (index: integer): TTMXObject;
		public
			property Objects[index: integer]: TTMXObject read GetObject; default;
			function Count: integer;
		protected
			procedure HandleLoad (info: TMap); override;
			destructor Destroy; override;
		private
			procedure AddObject (obj: TTMXObject);
	end;

	TTMXTile = class (TTMXNode)
		public
			tileID: GIDInt;
			image: TTMXTileImage;
			tileset: TTMXTileSet;
		protected
			procedure HandleLoad (info: TMap); override;
		private
			constructor Create(inTileSet: TTMXTileSet; inID: GIDInt); overload;
			procedure LoadImageTag (info: TMap);
	end;

	TTMXTileSet = class (TTMXNode)
		public
			firstGID: GIDInt;
			tileSize: TVec2;
			image: TTMXTileImage;
			index: integer;
		public
			function GetTile (tileID: integer): TTMXTile;
			function GetProperty (gid: GIDInt; propertyName: string): string; overload;
			function GetProperties (gid: GIDInt): TMap; overload;
			// TODO: swap this out
			function GetTileCoordForID (tileID: integer): TVec2; 			
		protected
			destructor Destroy; override;
		private
			columns: integer;
			tiles: TObjectList;
			tilecount: integer;
			externalPath: ansistring;

			constructor Create (_index: integer; path: ansistring; node: TDOMNode; info: TMap);

			procedure AddTile (tile: TTMXTile);
			procedure LoadAttributes (info: TMap);
			procedure LoadTileNodes(node: TDOMNode);
			function IsGIDValid (gid: GIDInt): boolean;
			function GetLastGID: GIDInt;
	end;

type
	TTMXObjectGroupList = specialize TFPGObjectList<TTMXObjectGroup>;
	TTMXTileSetList = specialize TFPGObjectList<TTMXTileSet>;
	TTMXTileList = specialize TFPGObjectList<TTMXTile>;
	TTMXNodeList = specialize TFPGObjectList<TTMXNode>;

type
	TTMXLayer = class (TTMXNode)
		public
			size: TVec2;
			tiles: TTMXTileList;
		public
			function GetTile (x, y: integer): TTMXTile;
			property TileMatrix[x, y: integer]: TTMXTile read GetTile; default;
		protected
			destructor Destroy; override;
			procedure HandleLoad (info: TMap); override;
		private
			procedure SetTile (tileset: TTMXTileSet; index: integer; gid: GIDInt);
	end;
	TTMXLayerList = specialize TFPGObjectList<TTMXLayer>;
	TTMXLayerMap = specialize TFPGMapObject<String, TTMXLayer>;

type
	TTMXFile = class
		public
			mapWidth: integer;
			mapHeight: integer;
			tileWidth: integer;
			tileHeight: integer;
			orientation: integer;
			tilesets: TTMXTileSetList;
			layers: TTMXLayerList;
			objectGroups: TTMXObjectGroupList;
			orderedLayers: TTMXNodeList;
			path: ansistring;
		public
			constructor Create (inPath: ansistring);
			destructor Destroy; override;
			function TileRectMake(x, y: integer): TRect; inline;
	end;

implementation
uses
	Variants, XMLRead;

{$define IMPLEMENTATION}
{$include include/Utils.inc}
{$undef IMPLEMENTATION}

const
	kTMXPropertyKeyMap = 'map';
	kTMXPropertyKeyTileSet = 'tileset';
	kTMXPropertyKeyImage = 'image';
	kTMXPropertyKeyLayer = 'layer';
	kTMXPropertyKeyData = 'data';
	kTMXPropertyKeyTile = 'tile';
	kTMXPropertyKeyProperties = 'properties';
	kTMXPropertyKeyProperty = 'property';
	kTMXPropertyKeyObjectGroup = 'objectgroup';
	kTMXPropertyKeyImageLayer = 'imagelayer';
	kTMXPropertyKeyGroup = 'group';
	kTMXPropertyKeyObject = 'object';
	
function NodeAttributes (node: TDOMNode; pool: TObjectList): TMap;
var
	i: integer;
begin
	result := TMap.Create;
	for i := 0 to node.Attributes.Length - 1 do
		result[node.Attributes.Item[i].NodeName] := node.Attributes.Item[i].NodeValue;
	if assigned(pool) then
		pool.Add(result);
end;
	
//$bookmark -
//$bookmark TMX NODE
//$bookmark -

procedure TTMXNode.AddPropertyTag (info: TMap);
begin
	// TODO: parse "type" key and set the param properly
	// i.e. bool "true" shouldn't be an actual string
	// <property name="solid" type="bool" value="true"/>
	AddProperty(info['name'], info['value']);
end;

procedure TTMXNode.AddProperty (name: string; value: Variant);
begin
	if m_properties = nil then
		m_properties := TMap.Create;
	m_properties[name] := value;
end;

function TTMXNode.GetProperty (name: string): Variant;
begin
	if m_properties <> nil then
		result := m_properties[name]
	else
		result := 0;
end;

destructor TTMXNode.Destroy;
begin
	if assigned(m_properties) then
		m_properties.Free;
	
	inherited Destroy;
end;

procedure TTMXNode.HandleLoad (info: TMap);
var
	data: variant;
begin
	if info.TryGetData('name', data) then
		name := data;

	if info.TryGetData('visible', data) then
	  visible := data
	else
		visible := true;
end;

constructor TTMXNode.Create (info: TMap);
begin
	HandleLoad(info);
end;

//$bookmark -
//$bookmark TMX TILE
//$bookmark -

constructor TTMXTile.Create(inTileSet: TTMXTileSet; inID: GIDInt);
begin
	tileset := inTileSet;
	tileID := inID;
end;

// <image> tag
procedure TTMXTile.LoadImageTag (info: TMap);
begin
	image.source := ExtractFileName(info['source']);
	image.size := V2(info['width'], info['height']);
	image.fullpath := image.source;
end;

procedure TTMXTile.HandleLoad (info: TMap);
begin
	// TODO: this is the unique ID in the <tile> tag from <tilesets>
	tileID := info['id'];
end;


//$bookmark -
//$bookmark TMX LAYER
//$bookmark -

procedure TTMXLayer.SetTile (tileset: TTMXTileSet; index: integer; gid: GIDInt);
begin
	if assigned(tileset) then
		tiles[index] := TTMXTile.Create(tileset, gid - tileset.firstGID)
	else
		tiles[index] := TTMXTile.Create(nil, gid);
end;

procedure TTMXLayer.HandleLoad (info: TMap);
var
	data: Variant;
begin
	inherited HandleLoad(info);

	tiles := TTMXTileList.Create(true);
	size := V2(info['width'], info['height']);
	tiles.Count := info['width'] * info['height'];
end;

function TTMXLayer.GetTile (x, y: integer): TTMXTile;
begin
	result := tiles[x + y * trunc(size.width)];
end;

destructor TTMXLayer.Destroy;
begin
	tiles.Free;

	inherited Destroy;
end;

//$bookmark -
//$bookmark TMX TILESET
//$bookmark -

function TTMXTileSet.GetLastGID: GIDInt;
begin
	result := firstGID + tilecount;
end;

// Return <tile> for local ID
// NOTE: this function can return nil if the tile has no defined
// properties
function TTMXTileSet.GetTile (tileID: integer): TTMXTile;
var
	tile: TTMXTile;
begin
	result := nil;
	for pointer(tile) in tiles do
		if tile.tileID = tileID then
			exit(tile);
end;

function TTMXTileSet.GetProperties (gid: GIDInt): TMap;
var
	tile: TTMXTile;
begin
	if IsGIDValid(gid) then
		begin
			tile := GetTile(gid - firstGID);
			if tile <> nil then
				result := tile.m_properties
			else
				result := nil;
		end
	else
		result := nil;
end;

function TTMXTileSet.GetProperty (gid: GIDInt; propertyName: string): string;
var
	tile: TTMXTile;
begin
	if IsGIDValid(gid) then
		begin
			tile := GetTile(gid - firstGID);
			if tile <> nil then
				result := tile.GetProperty(propertyName)
			else
				result := '';
		end
	else
		result := '';
end;

function TTMXTileSet.IsGIDValid (gid: GIDInt): boolean;
begin
	result := (gid >= firstGID) and (gid < GetLastGID);
end;

// TODO: this is wrong. use / and % to get x/y coords from index
function TTMXTileSet.GetTileCoordForID (tileID: integer): TVec2; 
var
	row: integer;
begin
	result := V2(0, 0);
	row := tileID;
	while row > columns do
		begin
			row -= columns;
			result.y += 1;
		end;
	result.x := row;
end;

procedure TTMXTileSet.AddTile (tile: TTMXTile);
begin
	tiles.Add(tile);
end;

procedure TTMXTileSet.LoadTileNodes(node: TDOMNode);
var
	pool: TObjectList;
	child, 
	propertiesNode, 
	imageNode: TDOMNode;
	tile: TTMXTile;
	attributes: TMap;
	i, j: integer;
begin
	// load <tile> nodes
	pool := TObjectList.Create(true);
	for i := 0 to node.ChildNodes.Length - 1 do
		begin
			if node.ChildNodes.Item[i].NodeName = kTMXPropertyKeyTile then
				begin
					child := node.ChildNodes.Item[i];
					tile := TTMXTile.Create(NodeAttributes(child, nil));
					
					// load <image> for collections of images
					imageNode := child.FindNode(kTMXPropertyKeyImage);
					if imageNode <> nil then
						tile.LoadImageTag(NodeAttributes(imageNode, pool));
					
					// load <properties>
					propertiesNode := child.FindNode(kTMXPropertyKeyProperties);
					if propertiesNode <> nil then
						for j := 0 to propertiesNode.ChildNodes.Length - 1 do
							tile.AddPropertyTag(NodeAttributes(propertiesNode.ChildNodes.Item[j], pool));

					AddTile(tile);
				end
			else if node.ChildNodes.Item[i].NodeName = kTMXPropertyKeyImage then
				begin
					attributes := NodeAttributes(node.ChildNodes.Item[i], pool);
					image.source := attributes['source'];
					image.size := V2(attributes['width'], attributes['height']);
					image.fullPath := image.source
				end;
		end;
	pool.Free;
end;

procedure TTMXTileSet.LoadAttributes (info: TMap);
begin
	name := info['name'];
	tileSize := V2(info['tilewidth'], info['tileheight']);
	columns := info['columns'];
	tilecount := info['tilecount'];
end;

destructor TTMXTileSet.Destroy;
begin
	tiles.Free;
	
	inherited Destroy;
end;

constructor TTMXTileSet.Create (_index: integer; path: ansistring; node: TDOMNode; info: TMap);
var
	data: variant;
	attributes: TMap;
	xml: TXMLDocument;
begin
	inherited Create(info);

	tiles := TObjectList.Create(true);
	firstGID := info['firstgid'];
	index := _index;

	// if there is a source attribute then we need to load an external file
	if info.TryGetData('source', data) then
		begin
			externalPath := ExtractFileDir(path);
			externalPath := externalPath+'/'+info['source'];
			Assert(FileExists(externalPath), 'The external tileset '+externalPath+' doesn''t exist.');
			ReadXMLFile(xml, externalPath);
			
			attributes := NodeAttributes(xml.DocumentElement, nil);
			LoadAttributes(attributes);
			attributes.Free;

			LoadTileNodes(xml.DocumentElement);
			xml.Free;
		end
	else
		begin
			LoadAttributes(info);
			LoadTileNodes(node);
		end;
end;

//$bookmark -
//$bookmark TMX OBJECT GROUP
//$bookmark -

function TTMXObjectGroup.Count: integer;
begin
	result := m_objects.Count;
end;

function TTMXObjectGroup.GetObject (index: integer): TTMXObject;
begin
	result := m_objects[index];
end;

procedure TTMXObjectGroup.AddObject (obj: TTMXObject);
begin
	m_objects.Add(obj);
end;

procedure TTMXObjectGroup.HandleLoad (info: TMap);
begin
	inherited HandleLoad(info);

	m_objects := TTMXObjectList.Create(true);
end;

destructor TTMXObjectGroup.Destroy;
begin
	m_objects.Free;
	
	inherited Destroy;
end;

//$bookmark -
//$bookmark TMX OBJECT
//$bookmark -

constructor TTMXObject.Create (inTileset: TTMXTileSet; info: TMap);
begin
	HandleLoad(info);
	tileset := inTileset;
	tileID := info['gid'] - tileset.firstGID;
end;

procedure TTMXObject.HandleLoad (info: TMap);
begin
	inherited HandleLoad(info);
	// TODO: this is a default property which should be in base class
	//tileID := info['id'];
	frame := RectMake(info['x'], info['y'] - info['height'], info['width'], info['height']);
end;

//$bookmark -
//$bookmark TMX FILE
//$bookmark -

function TTMXFile.TileRectMake(x, y: integer): TRect;
begin
	result := RectMake(x * self.tileWidth, y * self.tileHeight, self.tileWidth, self.tileHeight);
end;

destructor TTMXFile.Destroy;
begin
	tilesets.Free;
	layers.Free;
	objectGroups.Free;
	orderedLayers.Free;
end;

constructor TTMXFile.Create(inPath: ansistring);

	function TileSetForGID(gid: integer): TTMXTileSet;
	var
		tileset: TTMXTileSet;
	begin
		result := nil;
		for pointer(tileset) in tilesets do
			if tileset.IsGIDValid(gid) then
				exit(tileset);
		Assert(result <> nil, 'can''t find tileset for gid '+IntToStr(gid));
	end;

var
  node, child: TDOMNode;
	elem: TDOMElement;
  xml, tsx: TXMLDocument;
	root: TMap;
	key: string = '';
	i, x: integer;
	gid: string;
	tilesetIndex: integer;
	attributes: TMap;
	tileset: TTMXTileSet;
	layer: TTMXLayer;
	tile: TTMXTile;
	objectGroup: TTMXObjectGroup;
	obj: TTMXObject;
	pool: TObjectList;
begin
	path := inPath;
  try
    ReadXMLFile(xml, path);
		
		pool := TObjectList.Create(true);
		tilesets := TTMXTileSetList.Create(true);
		layers := TTMXLayerList.Create(true);
		objectGroups := TTMXObjectGroupList.Create(true);
		orderedLayers := TTMXNodeList.Create(false);
		tilesetIndex := 0;

		node := xml.DocumentElement;

		// map node
		if node.NodeName = kTMXPropertyKeyMap then
			begin
				attributes := NodeAttributes(node, pool);

				mapWidth := attributes['width'];
				mapHeight := attributes['height'];
				tileWidth := attributes['tilewidth'];
				tileHeight := attributes['tileheight'];

				if attributes['orientation'] = 'orthogonal' then
					orientation  := kTileLayerOrientationOrthogonal
				else if attributes['orientation'] = 'isometric' then
					orientation  := kTileLayerOrientationIsometric
				else
					Assert(false, 'Map orientation '+attributes['orientation']+' is not supported.');
			end;
		
		// start inside the root
		node := node.FirstChild;	

		while node <> nil do
			begin

				if node.nodename = kTMXPropertyKeyTileSet then
					begin
						attributes := NodeAttributes(node, pool);
						tileset := TTMXTileSet.Create(tilesetIndex, path, node, attributes);
						tilesets.Add(tileset);
						inc(tilesetIndex);
					end;
					
				if node.NodeName = kTMXPropertyKeyLayer then
					begin
						layer := TTMXLayer.Create(NodeAttributes(node, pool));
						layers.Add(layer);
						orderedLayers.Add(layer);

						// load <data> children
						child := node.FindNode(kTMXPropertyKeyData);
						if child <> nil then
							begin
								// if child has any attributes it is assumed to not be XML
								Assert(child.Attributes.Length = 0, 'layer <data> must be XML only.');
								for i := 0 to child.ChildNodes.Length - 1 do
									begin
										elem := TDOMElement(child.ChildNodes.Item[i]);
										gid := elem.GetAttribute('gid');
										if gid = '' then
											layer.SetTile(nil, i, kInvalidGID)
										else
											layer.SetTile(TileSetForGID(StrToInt(gid)), i, StrToInt(gid));
									end;
							end;
							
						// load <properties> children
						child := node.FindNode(kTMXPropertyKeyProperties);
						if child <> nil then
							for i := 0 to child.ChildNodes.Length - 1 do
								layer.AddPropertyTag(NodeAttributes(child.ChildNodes.Item[i], pool));
					end;
				
				if node.NodeName = kTMXPropertyKeyObjectGroup then
					begin
						objectGroup := TTMXObjectGroup.Create(NodeAttributes(node, pool));
						objectGroups.Add(objectGroup);
						orderedLayers.Add(objectGroup);

						// load <object>'s
						for i := 0 to node.ChildNodes.Length - 1 do
							if node.ChildNodes.Item[i].NodeName = kTMXPropertyKeyObject then
								begin
									child := node.ChildNodes.Item[i];
									
									attributes := NodeAttributes(child, pool);
									obj := TTMXObject.Create(TileSetForGID(attributes['gid']), attributes);
									objectGroup.AddObject(obj);

									// load <properties>
									child := child.FindNode(kTMXPropertyKeyProperties);
									if child <> nil then
										for x := 0 to child.ChildNodes.Length - 1 do
											obj.AddPropertyTag(NodeAttributes(child.ChildNodes.Item[x], pool));
								end
							else if node.ChildNodes.Item[i].NodeName = kTMXPropertyKeyProperties then
								begin
									// get objectgroup <properties>
									child := node.ChildNodes.Item[i];
									for x := 0 to child.ChildNodes.Length - 1 do
										objectGroup.AddPropertyTag(NodeAttributes(child.ChildNodes.Item[x], pool));
								end;
					end;

				if node.NodeName = kTMXPropertyKeyImageLayer then
					begin
						// TODO: how do we parse ../xxx paths?
						writeln(kTMXPropertyKeyImageLayer, ' not supported yet');
					end;
				
				if node.NodeName = kTMXPropertyKeyGroup then
					begin
						// TODO: how do we parse ../xxx paths?
						writeln(kTMXPropertyKeyGroup, ' not supported yet');
					end;

		  	node := node.NextSibling;
			end;
		
  finally
    xml.Free;
    pool.Free;
  end;
end;

end.