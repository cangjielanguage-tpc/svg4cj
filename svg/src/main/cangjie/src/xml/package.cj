/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */
package svg.xml

internal import std.collection.*
internal import std.collection.concurrent.*
internal import std.sync.*
internal import std.io.{InputStream, OutputStream}

public let W3_XML_NAMESPACE = "http://www.w3.org/XML/1998/namespace"

// BA: ByteArray
// S: Space
// PRE: Prefix
// SUF: Suffix
let BA_XML_S = "xml ".toArray()
let BA_DOCTYPE = "DOCTYPE".toArray()
let BA_CDATA_PRE = "[CDATA[".toArray()
let BA_CDATA_SUF = "]]>".toArray()
let BA_DASH_DASH = "--".toArray()
let BA_EMPTY_TAG_END = "/>".toArray()
let BA_XMLNS = "xmlns".toArray()
