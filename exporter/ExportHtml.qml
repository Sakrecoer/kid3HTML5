/**
 * \file ExportHtml.qml
 * Export static HTML files from templates to have a player.
 * https://github.com/Sakrecoer/kid3HTML5
 *
 * \b Project: Kid3
 * \author Urs Fleisch
 * \date 6 Jun 2015
 *
 * Copyright (C) 2015  Urs Fleisch
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Kid3 1.0

Kid3Script {
  onRun: {
    function storeTags(src, dst) {
      for (var prop in src) {
        var val = src[prop]
        if (val) {
          var key = prop.toLowerCase()
          if (key === "track number") {
            key = "track"
          } else if (key === "date") {
            key = "year"
          }
          dst[key] = val
        }
      }
    }

    function replaceTemplateParameters(tpl, tags) {
      var result = ""
      var end = 0
      while (end >= 0) {
        var begin = tpl.indexOf("%{", end)
        if (begin >= 0) {
          result += tpl.substring(end, begin)
          begin += 2
          end = tpl.indexOf("}", begin)
          if (end >= 0) {
            var key = tpl.substring(begin, end)
            result += (key in tags) ? tags[key] : ("%{" + key + "}")
            end += 1
          }
        } else {
          result += tpl.substring(end)
          end = -1
        }
      }
      return result
    }

    function splitFileName(fileName) {
      var dotPos = fileName.lastIndexOf(".")
      var ext = ""
      if (dotPos !== -1) {
        ext = fileName.substring(dotPos + 1)
        fileName = fileName.substring(0, dotPos)
      }
      return [fileName, ext]
    }

    function extensionToMimeType(ext) {
      switch (ext) {
      case "mp3":
        return "audio/mpeg"
      case "ogg":
        return "audio/ogg"
      case "flac":
        return "audio/x-flac"
      case "mpc":
        return "audio/x-musepack"
      case "aac":
        return "audio/aac"
      case "mp4":
        return "audio/mp4"
      case "spx":
        return "audio/x-speex"
      case "tta":
        return "audio/x-tta"
      case "wv":
        return "audio/x-wavpack"
      }
      return ext
    }

    function renderTrackData(tags) {
      var result = ""
      for (var key in tags) {
        if (key !== "lyrics" && key !== "picture") {
          result += "<p>" + key + ": <b>" + tags[key] + "</b></p>\n"
        }
      }
      return result
    }

    function getScriptDirectory() {
      var params = []
      if (typeof args !== "undefined") {
        params = args.slice(0)
      } else if (Qt.application.arguments) {
        // This only works with Qt 5.
        params = Qt.application.arguments.slice(0)
      }
      for (var i = 0; i < params.length; ++i) {
        if (params[i].indexOf("ExportHtml.qml") !== -1) {
          var scriptDir = params[i]
          var slashPos = scriptDir.lastIndexOf("/")
          if (slashPos !== -1) {
            scriptDir = scriptDir.substring(0, slashPos + 1)
          }
          return scriptDir
        }
      }
      return ""
    }

    var templateDir = getScriptDirectory()
    var indexTopTemplateFile = templateDir + "index_top.html"
    var indexTrackTemplateFile = templateDir + "index_track.html"
    var indexBottomTemplateFile = templateDir + "index_bottom.html"
    var trackTemplateFile = templateDir + "track.html"
    // The "" + are used for conversion to string.
    var indexTop = "" + script.readFile(indexTopTemplateFile)
    var indexTrack = "" + script.readFile(indexTrackTemplateFile)
    var indexBottom = "" + script.readFile(indexBottomTemplateFile)
    var trackTemplate = "" + script.readFile(trackTemplateFile)
    var index = ""
    var previousBaseName = ""
    var nextBaseName = ""
    var lastDir
    var defaultAlbumArt
    var md5Map = {}

    function doWork() {
      var fileName = app.selectionInfo.fileName
      var dirName = app.selectionInfo.filePath
      dirName = dirName.substring(0, dirName.length - fileName.length)
      var baseNameExt = splitFileName(fileName)
      var baseName = baseNameExt[0], extension = baseNameExt[1]

      if (dirName !== lastDir) {
        lastDir = dirName
        defaultAlbumArt = ""
        var existingImageFiles = script.listDir(dirName, ["*.png", "*.jpg"])
        for (var i = 0; i < existingImageFiles.length; ++i) {
          var imgFileName = existingImageFiles[i]
          defaultAlbumArt = imgFileName
          var fileData = script.readFile(dirName + imgFileName)
          if (script.getDataSize(fileData) !== 0) {
            md5Map[script.getDataMd5(fileData)] = imgFileName
          }
        }
      }
      var albumArt = defaultAlbumArt

      var tags = {}
      if (app.selectionInfo.tagFormatV1) {
        storeTags(app.getAllFrames(tagv1), tags)
      }
      if (app.selectionInfo.tagFormatV2) {
        storeTags(app.getAllFrames(tagv2), tags)

        var data = app.getPictureData()
        if (script.getDataSize(data) !== 0) {
          var md5 = script.getDataMd5(data)
          if (md5 in md5Map) {
            albumArt = md5Map[md5]
            console.log("Picture in %1 already exists in %2".
                        arg(fileName).arg(albumArt))
          } else {
            var format = "jpg"
            var img = script.dataToImage(data, format)
            var imgProps = script.imageProperties(img)
            if (!("width" in imgProps)) {
              format = "png"
              img = script.dataToImage(data, format)
              imgProps = script.imageProperties(img)
            }
            if ("width" in imgProps) {
              var picName = baseName + "." + format
              var picPath = dirName + picName
              if (!script.fileExists(picPath)) {
                if (script.writeFile(picPath, data)) {
                  md5Map[md5] = picName
                  console.log("Picture in %1 stored to %2".
                              arg(fileName).arg(picPath))
                  albumArt = picName
                } else {
                  console.log("Failed to write", picPath)
                }
              }
            }
          }
        }
      }
      var hasTags = Object.keys(tags).length > 0
      if (hasTags) {
        tags["trackdata"] = renderTrackData(tags)
        tags["filename"] = fileName
        tags["basename"] = baseName
        var durationMatches = app.selectionInfo.detailInfo.match(/[\d:]+$/)
        if (durationMatches.length > 0) {
          tags["duration"] = durationMatches[0]
        }
        if (!("comment" in tags)) {
          tags["comment"] = ""
        }
        tags["mimetype"] = extensionToMimeType(extension)
        tags["albumart"] = albumArt
      }
      // Already go to the next file in order to get the next file name.
      var hasNextFile, nextFileName
      while ((hasNextFile = app.nextFile())) {
        nextFileName = app.selectionInfo.fileName
        if (nextFileName) {
          nextBaseName = splitFileName(nextFileName)[0]
          break
        }
      }
      if (hasTags) {
        tags["previous_basename"] = previousBaseName ? previousBaseName
                                                     : baseName
        tags["next_basename"] = nextBaseName
        if (!index) {
          index += replaceTemplateParameters(indexTop, tags)
        }
        index += replaceTemplateParameters(indexTrack, tags)
        var track = replaceTemplateParameters(trackTemplate, tags)
        script.writeFile(dirName + baseName + ".html", track)
      }
      if (!hasNextFile) {
        index += replaceTemplateParameters(indexBottom, tags)
        script.writeFile(dirName + "index.html", index)
        // Copy stylesheets if necessary.
        var cssFiles = script.listDir(templateDir, ["*.css"])
        for (var i = 0; i < cssFiles.length; ++i) {
          var cssFileName = cssFiles[i]
          var dstPath = dirName + cssFileName
          if (!script.fileExists(dstPath)) {
            script.writeFile(dstPath,
                             script.readFile(templateDir + cssFileName))
          }
        }
        Qt.quit()
      } else {
        if (baseName) {
          previousBaseName = baseName
        }
        setTimeout(doWork, 1)
      }
    }

    app.firstFile()
    doWork()
  }
}
