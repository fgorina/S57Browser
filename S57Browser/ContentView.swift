//
//  ContentView.swift
//  S57Test
//
//  Created by Francisco Gorina Vanrell on 18/4/23.
//

import SwiftUI
import S57Parser
import MapKit
import Combine

struct ContentView: View {
    @State var filename = "Filename"
    @State var showFileChooser = false
    @State var error : String = ""
    @State var s57 : S57Parser = S57Parser()
    @State var items : [DataItem] = []
    @State var anItem : DataItem?
    @State var keys : [String] = []
    @State var field : DataItemField?
    @State var raw : Bool = true
    
    @State var package : S57Package?
    
    @State var featureClasses : [(UInt16, String)] = []
    @State var featureClass : (UInt16, String)?
    @State var features : [S57Feature] = []
    @State var aFeature : [S57Feature] = []
    @State var attributes : [S57Attribute] = []
    @State var nAttributes : [S57Attribute] = []
    @State var aVector : S57Vector?
    @State var otherVector : S57Vector?
    @State var vectorAttributes : [S57Attribute] = []
    @State var otherVectorAttributes : [S57Attribute] = []
    
    @State var isImporting = false
    
    @State var region : MKCoordinateRegion = MKCoordinateRegion.world
    @State var zoom : Double = 0.0
    @State var catalogZoom : Double = 0.0
    
    @State var multiSelection = Set<UInt16>()
    @State var multiSelectionp = Set<UInt16>()
    
    @State var catalogRegion : MKCoordinateRegion = .world
    @State var catalogItems : [any S57Displayable] = []
    
    @State var lastTap : MapTap?
    
    @State var onlyMap : Bool = false
    
    @State var showSelector : Bool = false
    
    
    func processTap(_ tap: MapTap){
        
        var someFeatures = self.features.filter { value in
            
            if let region = value.region{
                if value.prim == .point{
                    return tap.rect.contains(MKMapPoint(region.center))
                }else{
                    return region.mapRect.intersects(tap.rect)
                }
            }
            return false
        }
        
        someFeatures.sort { (f1 : S57Feature, f2 : S57Feature) in
            if f1.prim == .point && f2.prim != .point{
                return true
            }else if f1.prim != .point && f2.prim == .point {
                return false
            }else if f1.prim == .line && f2.prim != .line {
                return true
            }else if f1.prim != .line && f2.prim == .line {
                return false
            }else{
                return f1.id < f2.id
            }
        }
        
        var someAttributes : [S57Attribute] = []
        var somenAttributes : [S57Attribute] = []
        
        if !someFeatures.isEmpty{
            someAttributes = (someFeatures[0].attributes.map({ (key, value) in
                value
            })).sorted(by: { v1, v2 in
                v1.attribute < v2.attribute
            })
            
            somenAttributes = (someFeatures[0].nationalAttributes.map({ (key, value) in
                value
            })).sorted(by: { v1, v2 in
                v1.attribute < v2.attribute
            })
        }
        
        DispatchQueue.main.async{
            aFeature = someFeatures
            attributes = someAttributes
            nAttributes = somenAttributes
            
        }
        
    }
    
    func lookup(items : [any S57Displayable], loc : CLLocationCoordinate2D) -> (any S57Displayable)?{
        
        return items.filter { item in
            if let region = item.region{
                return region.contains(loc)
            }else{
                return false
            }
        }.sorted { (s1 :S57Displayable, s2: S57Displayable) in
            return s1.region?.area  ?? MKCoordinateRegion.world.area < s2.region?.area ?? MKCoordinateRegion.world.area
        }.first
    }
    
    func openURL(url: URL){
        
        
        self.filename = url.lastPathComponent
        
        if url.isDirectory  || filename == "CATALOG.031"{
            Task{
                var someURL =  url
                
                if !someURL.isDirectory {
                    let path = someURL.path.replacingOccurrences(of: "CATALOG.031", with: "")
                    someURL = URL(fileURLWithPath: path)
                }
                
                let somePackage = try S57Package(url: someURL)
                
                DispatchQueue.main.async {
                    self.package = somePackage
                    catalogItems = somePackage.catalog
                    catalogRegion = somePackage.region
                    raw = false
                }
            }
        }else{
            Task{
                if url.startAccessingSecurityScopedResource() {
                    
                    s57.url = url
                    package = nil
                    
                    try s57.parse()
                    url.stopAccessingSecurityScopedResource()
                    
                    DispatchQueue.main.async {
                        items = s57.items.sorted(by: { d1, d2 in
                            d1.uniqueId < d2.uniqueId
                        })
                        
                        features  = s57.features.map({ (key: UInt64, value: S57Feature) in
                            value
                        }).sorted(by: { f1, f2 in
                            if f1.decodedObjl != f2.decodedObjl {
                                return f1.decodedObjl ?? "\(f1.objl)" < f2.decodedObjl ?? "\(f2.objl)"
                            }else {
                                return f1.rcid < f2.rcid
                            }
                        })
                    }
                }
            }
        }
        
    }
    var body: some View {
        
        
        
        //MARK: - Selector
        
        
        let selector = Group {
            List(selection: $multiSelectionp.onChange({ ms in
                
                featureClass = featureClasses.first(where: { element in
                    let ele = ms.first
                    return element.0 == ele
                })
                
                
                features = package!.currentFeatures.values.filter({ f in
                    ms.contains(f.objl)
                }).sorted(by: { (f1 : S57Feature, f2 : S57Feature) in
                    if f1.prim == .point && f2.prim != .point{
                        return true
                    }else if f1.prim != .point && f2.prim == .point {
                        return false
                    }else if f1.prim == .line && f2.prim != .line {
                        return true
                    }else if f1.prim != .line && f2.prim == .line {
                        return false
                    }else{
                        return f1.id < f2.id
                    }
                }
                ).reversed()
            })
            ){
                
                ForEach(featureClasses, id: \.0) { fc in
                    Text("\(fc.1) (\(fc.0))")
                }
                
                
            }
        }
        //MARK: - Info View
        
        let infoView = Group {
            if !aFeature.isEmpty {
                let aFeature = aFeature[0]
                VStack{
                    
                    List{
                        Section("General"){
                            Text("Record id: \(aFeature.rcnm) \(aFeature.rcid)")
                            Text("Object id: \(aFeature.agen) \(aFeature.fidn) \(aFeature.fids) ")
                            Text("Object class: \(aFeature.objl) \(aFeature.decodedObjl ?? "") ")
                            Text("Updating: \(aFeature.ruin.description) \(aFeature.rver) ")
                            Text("Geometric shape: \(aFeature.prim.description)")
                            Text("Envelope: \(aFeature.region?.description ?? "")")
                            if let l = aFeature.region?.center{
                                Text("Decimal \(l.latitude) \(l.longitude)")
                            }
                            
                        }
                        Section("Attributes"){
                            ForEach(attributes) {element in
                                Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                            }
                        }
                        Section("National Attributes"){
                            ForEach(nAttributes) {element in
                                Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                
                            }
                        }
                        
                        Section("Related Features"){
                            ForEach(aFeature.ffpt) {element in
                                let ri : String = element.relationshipIndicator.description
                                if let referencedFeature = element.feature { //s57.features[element.id] {
                                    let objl = referencedFeature.decodedObjl ?? ""
                                    
                                    Text("\(ri) : \(objl) (\(referencedFeature.agen) \(referencedFeature.fidn) \(referencedFeature.fids)) \(element.comment)")
                                        .onTapGesture {
                                            self.aFeature = [referencedFeature]
                                            attributes = referencedFeature.attributes.map({ (key, value) in
                                                value
                                            })
                                            nAttributes = referencedFeature.nationalAttributes.map({ (key, value) in
                                                value
                                            })
                                            aVector = nil
                                            otherVector = nil
                                            
                                        }
                                }else {
                                    Text("\(ri) Not found referenced feature")
                                }
                                
                            }
                        }
                        
                    }
                }
            }
        }
        
        
        //MARK: - PackageView
        
        let packageView =  Group {
            if package != nil {
                HStack {
                    VStack{
                        
                        MapView(features: $catalogItems,
                                region: $catalogRegion,
                                currentZoom: $catalogZoom,
                                tap: $lastTap.onChange({ tap in
                            if let tap = tap{
                                if let item = lookup(items: catalogItems, loc: tap.location.coordinate) as? S57CatalogItem{
                                    if item.implementation != .txt {
                                        Task{
                                            do {
                                                try package!.select(item: item)
                                                features = []
                                                aFeature = []
                                                
                                            }catch{
                                                print("Error \(error)")
                                            }
                                            DispatchQueue.main.async{
                                                featureClasses = package!.currentFeatureClasses
                                            }
                                        }
                                    }
                                }
                            }
                        })
                                
                                
                                
                        )
                        .frame(width: 400, height: 400)
                        
                        
                        List{
                            
                            Section("Catalog"){
                                ForEach(package!.catalog){item in
                                    VStack(alignment: .leading){
                                        Text(item.file)
                                        Text(item.descCoordinates)
                                    }
                                    .onTapGesture {
                                        if item.implementation != .txt {
                                            Task{
                                                do {
                                                    try package!.select(item: item)
                                                    features = []
                                                    aFeature = []
                                                    
                                                }catch{
                                                    print("Error \(error)")
                                                }
                                                DispatchQueue.main.async{
                                                    featureClasses = package!.currentFeatureClasses
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                    List(selection: $multiSelectionp.onChange({ ms in
                        

                        featureClass = featureClasses.first(where: { element in
                            let ele = ms.first
                            return element.0 == ele
                        })
                        
                        
                        features = package!.currentFeatures.values.filter({ f in
                            ms.contains(f.objl)
                        }).sorted(by: { (f1 : S57Feature, f2 : S57Feature) in
                            if f1.prim == .point && f2.prim != .point{
                                return true
                            }else if f1.prim != .point && f2.prim == .point {
                                return false
                            }else if f1.prim == .line && f2.prim != .line {
                                return true
                            }else if f1.prim != .line && f2.prim == .line {
                                return false
                            }else{
                                return f1.id < f2.id
                            }
                        }
                        ).reversed()
                        if !features.isEmpty{
                            
                            if let someRegion = features[0].region{
                                
                                region = features.reduce(someRegion, { acum, f in
                                    if let reg = f.region {
                                        return reg.union(acum)
                                    }else{
                                        return acum
                                    }
                                }).resizedByFactor(1.5)
                            }
                            aFeature = [features[0] as S57Feature]
                            attributes = (aFeature[0].attributes.map({ (key, value) in
                                value
                            })).sorted(by: { v1, v2 in
                                v1.attribute < v2.attribute
                            })
                            nAttributes = (aFeature[0].nationalAttributes.map({ (key, value) in
                                value
                            })).sorted(by: { v1, v2 in
                                v1.attribute < v2.attribute
                            })
                            aVector = nil
                            
                            otherVector = nil
                        }
                    })
                    ){
                        
                        
                        Section(package?.currentItem?.file ?? ""){
                            ForEach(featureClasses, id: \.0) { fc in
                                Text("\(fc.1) (\(fc.0))")
                            }
                        }
                    }
                    
                    if featureClass != nil {
                        List{
                            Section(featureClass?.1 ?? ""){
                                ForEach(features, id : \.id) {element in
                                    Text("\(element.decodedObjl ?? "") (\(element.rcid))")
                                        .onTapGesture {
                                            aFeature[0] = element
                                            attributes = (aFeature[0].attributes.map({ (key, value) in
                                                value
                                            }) ).sorted(by: { v1, v2 in
                                                v1.attribute < v2.attribute
                                            })
                                            nAttributes = (aFeature[0].nationalAttributes.map({ (key, value) in
                                                value
                                            })).sorted(by: { v1, v2 in
                                                v1.attribute < v2.attribute
                                            })
                                            region = element.region?.resizedByFactor(2.0) ?? .world
                                            aVector = nil
                                            otherVector = nil
                                        }
                                }
                            }
                        }
                    }
                    
                    if !aFeature.isEmpty {
                        let aFeature = aFeature[0]
                        VStack{
                            
                            List{
                                Section("General"){
                                    Text("Record id: \(aFeature.rcnm) \(aFeature.rcid)")
                                    Text("Object id: \(aFeature.agen) \(aFeature.fidn) \(aFeature.fids) ")
                                    Text("Object class: \(aFeature.objl) \(aFeature.decodedObjl ?? "") ")
                                    Text("Updating: \(aFeature.ruin.description) \(aFeature.rver) ")
                                    Text("Geometric shape: \(aFeature.prim.description)")
                                    Text("Envelope: \(aFeature.region?.description ?? "")")
                                    if let l = aFeature.region?.center{
                                        Text("Decimal \(l.latitude) \(l.longitude)")
                                    }
                                    
                                }
                                Section("Attributes"){
                                    ForEach(attributes) {element in
                                        Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                        Text("\(element.attribute) : \(element.value)")
                                        
                                    }
                                }
                                Section("National Attributes"){
                                    ForEach(nAttributes) {element in
                                        Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                        
                                    }
                                }
                                
                                Section("Related Features"){
                                    ForEach(aFeature.ffpt) {element in
                                        let ri : String = element.relationshipIndicator.description
                                        if let referencedFeature = element.feature { //s57.features[element.id] {
                                            let objl = referencedFeature.decodedObjl ?? ""
                                            
                                            Text("\(ri) : \(objl) (\(referencedFeature.agen) \(referencedFeature.fidn) \(referencedFeature.fids)) \(element.comment)")
                                                .onTapGesture {
                                                    self.aFeature = [referencedFeature]
                                                    attributes = referencedFeature.attributes.map({ (key, value) in
                                                        value
                                                    })
                                                    nAttributes = referencedFeature.nationalAttributes.map({ (key, value) in
                                                        value
                                                    })
                                                    aVector = nil
                                                    otherVector = nil
                                                    
                                                }
                                        }else {
                                            Text("\(ri) Not found referenced feature")
                                        }
                                        
                                    }
                                }
                                Section("Map"){
                                    MapView(features: Binding<[any S57Displayable]>(
                                        get: { self.features as [any S57Displayable]},
                                        set: { self.features = $0 as? [S57Feature] ?? []}
                                    ), region: $region, currentZoom: $zoom, tap: $lastTap.onChange({ tap in
                                        
                                        print("Location \(tap!.location)")
                                    })
                                    )
                                    .frame(width: 400, height: 400)
                                    
                                }
                                
                                Section("Geometry"){
                                    ForEach(aFeature.fspt) {element in
                                        let usage = element.usageIndicator.description
                                        if let referencedVector  = element.vector { // s57.vectors[element.id] {
                                            
                                            Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) )as \(usage)")
                                                .onTapGesture {
                                                    aVector = referencedVector
                                                    vectorAttributes = referencedVector.attributes.map({ (key, value) in
                                                        value
                                                    })
                                                    otherVector = nil
                                                }
                                        }else {
                                            Text("Not found referenced vector \(element.id)")
                                        }
                                        
                                    }
                                }
                                /*  Section("Coordinates"){
                                 ForEach(aFeature.coordinates) {element in
                                 
                                 Text("\(element.latitude), \(element.longitude) : \( element.depth?.formatted() ?? "" )")
                                 }
                                 }
                                 */
                                
                            }
                            
                            
                        }
                        
                        
                    }
                    
                    if let someVector = aVector {
                        
                        List{
                            Section("General"){
                                Text("\(someVector.rcnmDescription)")
                                Text("Record id: \(someVector.rcnm) \(someVector.rcid)")
                                Text("Updating: \(someVector.ruin.description) \(someVector.rver) ")
                            }
                            Section("Attributes"){
                                ForEach(vectorAttributes) {element in
                                    Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                    
                                }
                            }
                            Section("Linked Vectors"){
                                ForEach(someVector.recordPointers) {element in
                                    let usage = element.usageIndicator.description
                                    if let referencedVector  = element.vector { //s57.vectors[element.id] {
                                        
                                        Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) ) as \(usage)")
                                            .onTapGesture {
                                                otherVector = referencedVector
                                                otherVectorAttributes = referencedVector.attributes.map({ (key , value) in
                                                    value
                                                })
                                            }
                                    }else {
                                        Text("Not found referenced vector \(element.id)")
                                    }
                                    
                                }
                            }
                            Section("Coordinates"){
                                ForEach(someVector.coordinates) {element in
                                    Text("\(element.latitude), \(element.longitude) : \(someVector.sounding ? element.depth?.formatted() ?? "" : "")")
                                }
                            }
                        }
                        
                    }
                    
                    if let otherVector = otherVector {
                        
                        List{
                            Section("General"){
                                Text("\(otherVector.rcnmDescription)")
                                Text("Record id: \(otherVector.rcnm) \(otherVector.rcid)")
                                Text("Updating: \(otherVector.ruin.description) \(otherVector.rver) ")
                            }
                            Section("Attributes"){
                                ForEach(otherVectorAttributes) {element in
                                    Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                    
                                }
                            }
                            
                            Section("Coordinates"){
                                ForEach(otherVector.coordinates) {element in
                                    Text("\(element.latitude), \(element.longitude) : \(otherVector.sounding ? element.depth?.formatted() ?? "" : "")")
                                }
                            }
                            
                            Section("Linked Vectors"){
                                ForEach(otherVector.recordPointers) {element in
                                    let usage = element.usageIndicator.description
                                    if let referencedVector  = element.vector { //s57.vectors[element.id] {
                                        
                                        Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) )as \(usage)")
                                        
                                    }else {
                                        Text("Not found referenced vector \(element.id)")
                                    }
                                    
                                }
                            }
                        }
                        
                    }
                    
                    
                }
            }
        }
        
        //MARK: - RawView
        let rawView =
        Group{
            HStack{
                
                List{
                    Section("Objects"){
                        ForEach(items) {element in
                            Text(element.names)
                                .onTapGesture {
                                    anItem = element
                                    keys = anItem?.fields.keys.map{$0} ?? []
                                }
                        }
                    }
                }
                if let anItem = anItem {
                    List{
                        Section("Fields"){
                            ForEach(keys, id:\.self) {key in
                                Text("\(key) \(anItem.fields[key]?.name ?? "")")
                                    .onTapGesture {
                                        field = anItem.fields[key]
                                    }
                            }
                        }
                    }
                }
                
                if let field = field {
                    
                    List{
                        Section("Attributes"){
                            ForEach(field.properties, id:\.id){ value in
                                Section{
                                    Text(value.description)
                                }
                                
                            }
                        }
                    }
                }
                
                
            }
        }
        
        //MARK: - FeatureView
        let featureView = Group {
            
            HStack {
                
                List(selection: $multiSelection.onChange({ ms in
                    
                    featureClass = featureClasses.first(where: { element in
                        let ele = ms.first
                        return element.0 == ele
                    })
                    
                    
                    features = s57.features.values.filter({ f in
                        ms.contains(f.objl)
                    }).sorted(by: { f1, f2 in
                        f1.rcid < f2.rcid
                    })
                    if !features.isEmpty{
                        
                        if let someRegion = features[0].region{
                            
                            region = features.reduce(someRegion, { acum, f in
                                if let reg = f.region {
                                    return reg.union(acum)
                                }else{
                                    return acum
                                }
                            }).resizedByFactor(1.5)
                        }
                        aFeature = [features[0]]
                        attributes = (aFeature[0].attributes.map({ (key, value) in
                            value
                        })).sorted(by: { v1, v2 in
                            v1.attribute < v2.attribute
                        })
                        nAttributes = (aFeature[0].nationalAttributes.map({ (key, value) in
                            value
                        })).sorted(by: { v1, v2 in
                            v1.attribute < v2.attribute
                        })
                        aVector = nil
                        
                        otherVector = nil
                    }
                })
                ){
                    Section("Object Classes"){
                        ForEach(s57.featureClasses, id: \.0) { fc in
                            Text("\(fc.1) (\(fc.0))")
                            /*                                .onTapGesture {
                             featureClass = fc
                             features = s57.features.values.filter({ f in
                             f.objl == fc.0
                             }).sorted(by: { f1, f2 in
                             f1.rcid < f2.rcid
                             })
                             if !features.isEmpty{
                             
                             if let someRegion = features[0].region{
                             
                             region = features.reduce(someRegion, { acum, f in
                             if let reg = f.region {
                             return reg.union(acum)
                             }else{
                             return acum
                             }
                             })
                             }
                             aFeature = [features[0]]
                             attributes = (aFeature[0].attributes.map({ (key, value) in
                             value
                             })).sorted(by: { v1, v2 in
                             v1.attribute < v2.attribute
                             })
                             nAttributes = (aFeature[0].nationalAttributes.map({ (key, value) in
                             value
                             })).sorted(by: { v1, v2 in
                             v1.attribute < v2.attribute
                             })
                             aVector = nil
                             
                             otherVector = nil
                             }
                             }*/
                        }
                    }
                }
                
                if featureClass != nil {
                    List{
                        Section(featureClass?.1 ?? ""){
                            ForEach(features, id: \.id) {element in
                                Text("\(element.decodedObjl ?? "") (\(element.rcid))")
                                    .onTapGesture {
                                        aFeature = [element]
                                        
                                        attributes = (aFeature[0].attributes.map({ (key, value) in
                                            value
                                        })).sorted(by: { v1, v2 in
                                            v1.attribute < v2.attribute
                                        })
                                        nAttributes = (aFeature[0].nationalAttributes.map({ (key, value) in
                                            value
                                        })).sorted(by: { v1, v2 in
                                            v1.attribute < v2.attribute
                                        })
                                        region = element.region?.resizedByFactor(2.0) ?? .world
                                        aVector = nil
                                        otherVector = nil
                                    }
                            }
                        }
                    }
                }
                
                if !aFeature.isEmpty {
                    let aFeature = aFeature[0]
                    VStack{
                        
                        List{
                            Section("General"){
                                Text("Record id: \(aFeature.rcnm) \(aFeature.rcid)")
                                Text("Object id: \(aFeature.agen) \(aFeature.fidn) \(aFeature.fids) ")
                                Text("Object class: \(aFeature.objl) \(aFeature.decodedObjl ?? "") ")
                                Text("Updating: \(aFeature.ruin.description) \(aFeature.rver) ")
                                Text("Geometric shape: \(aFeature.prim.description)")
                                Text("Envelope: \(aFeature.region?.description ?? "")")
                                
                            }
                            Section("Attributes"){
                                ForEach(attributes) {element in
                                    Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                    
                                }
                            }
                            Section("National Attributes"){
                                ForEach(nAttributes) {element in
                                    Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                    
                                }
                            }
                            
                            Section("Related Features"){
                                ForEach(aFeature.ffpt) {element in
                                    let ri : String = element.relationshipIndicator.description
                                    if let referencedFeature = element.feature { //s57.features[element.id] {
                                        let objl = referencedFeature.decodedObjl ?? ""
                                        
                                        Text("\(ri) : \(objl) (\(referencedFeature.agen) \(referencedFeature.fidn) \(referencedFeature.fids)) \(element.comment)")
                                            .onTapGesture {
                                                self.aFeature = [referencedFeature]
                                                attributes = referencedFeature.attributes.map({ (key, value) in
                                                    value
                                                })
                                                nAttributes = referencedFeature.nationalAttributes.map({ (key, value) in
                                                    value
                                                })
                                                aVector = nil
                                                otherVector = nil
                                                
                                            }
                                    }else {
                                        Text("\(ri) Not found referenced feature")
                                    }
                                    
                                }
                            }
                            
                            MapView(features:  Binding<[any S57Displayable]>(
                                get: { self.features as [any S57Displayable]},
                                set: { self.features = $0 as? [S57Feature] ?? []}
                            ), region: $region, currentZoom: $zoom, tap: $lastTap)
                            .frame(width: 400, height: 400)
                            
                            
                            Section("Geometry"){
                                ForEach(aFeature.fspt) {element in
                                    let usage = element.usageIndicator.description
                                    if let referencedVector  = element.vector { // s57.vectors[element.id] {
                                        
                                        Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) )as \(usage)")
                                            .onTapGesture {
                                                aVector = referencedVector
                                                vectorAttributes = referencedVector.attributes.map({ (key, value) in
                                                    value
                                                })
                                                otherVector = nil
                                            }
                                    }else {
                                        Text("Not found referenced vector \(element.id)")
                                    }
                                    
                                }
                            }
                            Section("Coordinates"){
                                ForEach(aFeature.coordinates.exterior) {element in
                                    
                                    Text("\(element.latitude), \(element.longitude) : \( element.depth?.formatted() ?? "" )")
                                }
                            }
                            
                        }
                        
                        
                    }
                    
                    
                }
                
                if let someVector = aVector {
                    
                    List{
                        Section("General"){
                            Text("\(someVector.rcnmDescription)")
                            Text("Record id: \(someVector.rcnm) \(someVector.rcid)")
                            Text("Updating: \(someVector.ruin.description) \(someVector.rver) ")
                        }
                        Section("Attributes"){
                            ForEach(vectorAttributes) {element in
                                Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                
                            }
                        }
                        Section("Linked Vectors"){
                            ForEach(someVector.recordPointers) {element in
                                let usage = element.usageIndicator.description
                                if let referencedVector  = element.vector { //s57.vectors[element.id] {
                                    
                                    Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) ) as \(usage)")
                                        .onTapGesture {
                                            otherVector = referencedVector
                                            otherVectorAttributes = referencedVector.attributes.map({ (key , value) in
                                                value
                                            })
                                        }
                                }else {
                                    Text("Not found referenced vector \(element.id)")
                                }
                                
                            }
                        }
                        Section("Coordinates"){
                            ForEach(someVector.coordinates) {element in
                                Text("\(element.latitude), \(element.longitude) : \(someVector.sounding ? element.depth?.formatted() ?? "" : "")")
                            }
                        }
                    }
                    
                }
                
                if let otherVector = otherVector {
                    
                    List{
                        Section("General"){
                            Text("\(otherVector.rcnmDescription)")
                            Text("Record id: \(otherVector.rcnm) \(otherVector.rcid)")
                            Text("Updating: \(otherVector.ruin.description) \(otherVector.rver) ")
                        }
                        Section("Attributes"){
                            ForEach(otherVectorAttributes) {element in
                                Text("\(element.decodedAttribute ?? "") : \(element.decodedValue ?? "")")
                                
                            }
                        }
                        
                        Section("Coordinates"){
                            ForEach(otherVector.coordinates) {element in
                                Text("\(element.latitude), \(element.longitude) : \(otherVector.sounding ? element.depth?.formatted() ?? "" : "")")
                            }
                        }
                        
                        Section("Linked Vectors"){
                            ForEach(otherVector.recordPointers) {element in
                                let usage = element.usageIndicator.description
                                if let referencedVector  = element.vector { //s57.vectors[element.id] {
                                    
                                    Text("Vector \(referencedVector.rcnmDescription) (\(referencedVector.rcnm) \(referencedVector.rcid) )as \(usage)")
                                    
                                }else {
                                    Text("Not found referenced vector \(element.id)")
                                }
                                
                            }
                        }
                    }
                    
                }
                
                
            }
        }
        
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("S57 Tests")
            Text(filename)
            Text(error)
            HStack{
                Button("select File")
                {
                    isImporting = true
                }
                Spacer()
                
                Toggle("Selector", isOn: $showSelector)
                    .toggleStyle(.button)

                Toggle("Raw", isOn: $raw)
                    .toggleStyle(.button)
                
                Toggle("Map", isOn: $onlyMap)
                    .toggleStyle(.button)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [ .folder, .item],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    openURL(url: selectedFile)
                } catch {
                    // Handle failure.
                    print("Unable to read file contents")
                    print(error.localizedDescription)
                }
            }
            
            if onlyMap {
                ZStack{
                    HStack{
                        MapView(features: Binding<[any S57Displayable]>(
                            get: { self.features as [any S57Displayable]},
                            set: { self.features = $0 as? [S57Feature] ?? []}
                        ), region: $region, currentZoom: $zoom, tap: $lastTap.onChange({ tap in
                            if let tap = tap{
                                processTap(tap)
                            }
                            
                        })
                        )
                        infoView.frame(width: 300)
                    }
                    if showSelector{
                        selector.frame(width: 400.0, height: 400.0)
                    }
                }
            }
            else if let _ = package {
                packageView
            }else {
                if raw {
                    rawView
                } else {
                    featureView
                }
            }
            
        }
        .padding()
    }
    init(){
        let url = FileManager.default.getDocumentsDirectory()
        print(url)
        
        
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
