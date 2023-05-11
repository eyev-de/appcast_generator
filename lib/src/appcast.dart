import 'dart:io';
import 'package:xml/xml.dart';

class Appcast {
  final AppcastMeta meta;
  final List<AppcastItem> items;
  Appcast({
    required this.meta,
    required this.items,
  });
}

class AppcastUtil {
  static Appcast? parseAppcastItemsFromFile(File file) {
    final contents = file.readAsStringSync();
    return parseItemsFromXMLString(contents);
  }

  static Appcast? parseItemsFromXMLString(String xmlString) {
    if (xmlString.isEmpty) {
      return null;
    }
    var items = <AppcastItem>[];
    String? title;
    String? link;
    String? description;
    String? language;
    try {
      // Parse the XML
      final document = XmlDocument.parse(xmlString);
      document.findAllElements('channel').forEach((XmlNode itemElement) {
        itemElement.children.forEach((XmlNode childNode) {
          if (childNode is XmlElement) {
            final name = childNode.name.toString();
            if (name == 'item') return;
            if (name == 'title') {
              title = childNode.text;
            }
            if (name == 'link') {
              link = childNode.text;
            }
            if (name == 'description') {
              description = childNode.text;
            }
            if (name == 'language') {
              language = childNode.text;
            }
          }
        });
      });

      // look for all item elements in the rss/channel
      document.findAllElements('item').forEach((XmlElement itemElement) {
        String? title;
        String? itemDescription;
        String? dateString;
        String? fileURL;
        String? maximumSystemVersion;
        String? minimumSystemVersion;
        String? osString;
        final tags = <String>[];
        String? newVersion;
        String? itemVersion;
        String? enclosureVersion;
        int? length;
        String? signature;
        String? releaseNotes;

        itemElement.children.forEach((XmlNode childNode) {
          if (childNode is XmlElement) {
            final name = childNode.name.toString();
            if (name == AppcastConstants.ElementTitle) {
              title = childNode.text;
            } else if (name == AppcastConstants.ElementDescription) {
              itemDescription = childNode.text;
            } else if (name == AppcastConstants.ElementEnclosure) {
              childNode.attributes.forEach((XmlAttribute attribute) {
                if (attribute.name.toString() == AppcastConstants.AttributeVersion) {
                  enclosureVersion = attribute.value;
                } else if (attribute.name.toString() == AppcastConstants.AttributeOsType) {
                  osString = attribute.value;
                } else if (attribute.name.toString() == AppcastConstants.AttributeURL) {
                  fileURL = attribute.value;
                } else if (attribute.name.toString() == AppcastConstants.AttributeLength) {
                  length = int.tryParse(attribute.value);
                } else if (attribute.name.toString() == AppcastConstants.AttributeSignature) {
                  signature = attribute.value;
                }
              });
            } else if (name == AppcastConstants.ElementMaximumSystemVersion) {
              maximumSystemVersion = childNode.text;
            } else if (name == AppcastConstants.ElementMinimumSystemVersion) {
              minimumSystemVersion = childNode.text;
            } else if (name == AppcastConstants.ElementPubDate) {
              dateString = childNode.text;
            } else if (name == AppcastConstants.ElementTags) {
              childNode.children.forEach((XmlNode tagChildNode) {
                if (tagChildNode is XmlElement) {
                  final tagName = tagChildNode.name.toString();
                  tags.add(tagName);
                }
              });
            } else if (name == AppcastConstants.AttributeVersion) {
              itemVersion = childNode.text;
            } else if (name == AppcastConstants.ElementReleaseNotesLink) {
              releaseNotes = childNode.text;
            }
          }
        });

        if (itemVersion == null) {
          newVersion = enclosureVersion;
        } else {
          newVersion = itemVersion;
        }

        // There must be a version
        if (newVersion == null || newVersion.isEmpty) {
          return null;
        }

        final item = AppcastItem(
          title: title,
          itemDescription: itemDescription,
          dateString: dateString,
          maximumSystemVersion: maximumSystemVersion,
          minimumSystemVersion: minimumSystemVersion,
          osString: osString,
          tags: tags,
          fileURL: fileURL,
          versionString: newVersion,
          contentLength: length,
          signature: signature,
          releaseNotesURL: releaseNotes,
        );
        items.add(item);
      });
    } catch (e) {
      print(e);
    }

    return Appcast(
      meta: AppcastMeta(
        title: title,
        link: link,
        description: description,
        language: language,
      ),
      items: items,
    );
  }

  static String? createXMLStringFromItems(Appcast appcast) {
    String? error;
    try {
      // if (appcast.items.isEmpty)
      //   throw 'Please provide at least one AppcastItem.';
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element('rss', nest: () {
        builder.attribute('xmlns:dc', 'http://purl.org/dc/elements/1.1/');
        builder.attribute(
          'xmlns:sparkle',
          'http://www.andymatuschak.org/xml-namespaces/sparkle',
        );
        builder.attribute('version', '2.0');

        builder.element('channel', nest: () {
          builder.element('title', nest: () {
            if (appcast.meta.title != null)
              builder.text(appcast.meta.title!);
            else
              throw 'This Appcast does not have a title.';
          });
          if (appcast.meta.link != null)
            builder.element('link', nest: () {
              builder.text(appcast.meta.link!);
            });
          if (appcast.meta.description != null)
            builder.element('description', nest: () {
              builder.text(appcast.meta.description!);
            });
          if (appcast.meta.language != null)
            builder.element('language', nest: () {
              builder.text(appcast.meta.language!);
            });
          for (final item in appcast.items)
            builder.element('item', nest: () {
              if (item.title == null) return error = 'Please provide the title of this update.';
              if (item.dateString == null) return error = 'Please provide the release date of this update.';
              if (item.fileURL == null) return error = 'Please provide a download link for this update.';
              if (item.versionString == null) return error = 'Please provide a version string for this update.';
              if (item.contentLength == null) return error = 'Please provide the content length in bytes of this update.';
              if (item.signature == null) return error = 'Please provide a signature';
              builder.element('title', nest: () {
                builder.text(item.title!);
              });
              if (item.releaseNotesURL != null)
                builder.element('sparkle:releaseNotesLink', nest: () {
                  builder.text(item.releaseNotesURL!);
                });
              builder.element('pubDate', nest: () {
                builder.text(item.dateString!);
              });
              builder.element('enclosure', nest: () {
                builder.attribute('url', item.fileURL!);
                builder.attribute('sparkle:version', item.versionString!);
                builder.attribute('sparkle:os', item.osString ?? 'windows');
                // var file = File(item.file);
                // file.lengthSync()
                builder.attribute('length', item.contentLength!);
                builder.attribute('type', 'application/octet-stream');
                builder.attribute('sparkle:signature', item.signature!);
              });
            });
        });
      });
      return builder.buildDocument().toXmlString(pretty: true, indent: '\t');
    } catch (error) {
      print(error);
    }
    print(error);
  }
}

class AppcastMeta {
  final String? title;
  final String? link;
  final String? description;
  final String? language;
  AppcastMeta({
    this.title,
    this.link,
    this.description,
    this.language,
  });
}

class AppcastItem {
  final String? title;
  final String? dateString;
  final String? itemDescription;
  final String? releaseNotesURL;
  final String? minimumSystemVersion;
  final String? maximumSystemVersion;
  final String? fileURL;
  final int? contentLength;
  final String? versionString;
  final String? osString;
  final String? displayVersionString;
  final String? infoURL;
  final List<String>? tags;
  final String? signature;

  AppcastItem({
    this.title,
    this.dateString,
    this.itemDescription,
    this.releaseNotesURL,
    this.minimumSystemVersion,
    this.maximumSystemVersion,
    this.fileURL,
    this.contentLength,
    this.versionString,
    this.osString,
    this.displayVersionString,
    this.infoURL,
    this.tags,
    this.signature,
  });
}

/// These constants taken from:
/// https://github.com/sparkle-project/Sparkle/blob/master/Sparkle/SUConstants.m
class AppcastConstants {
  static const String AttributeDeltaFrom = 'sparkle:deltaFrom';
  static const String AttributeDSASignature = 'sparkle:dsaSignature';
  static const String AttributeEDSignature = 'sparkle:edSignature';
  static const String AttributeSignature = 'sparkle:signature';
  static const String AttributeShortVersionString = 'sparkle:shortVersionString';
  static const String AttributeVersion = 'sparkle:version';
  static const String AttributeOsType = 'sparkle:os';

  static const String ElementCriticalUpdate = 'sparkle:criticalUpdate';
  static const String ElementDeltas = 'sparkle:deltas';
  static const String ElementMinimumSystemVersion = 'sparkle:minimumSystemVersion';
  static const String ElementMaximumSystemVersion = 'sparkle:maximumSystemVersion';
  static const String ElementReleaseNotesLink = 'sparkle:releaseNotesLink';
  static const String ElementTags = 'sparkle:tags';

  static const String AttributeURL = 'url';
  static const String AttributeLength = 'length';

  static const String ElementDescription = 'description';
  static const String ElementEnclosure = 'enclosure';
  static const String ElementLink = 'link';
  static const String ElementPubDate = 'pubDate';
  static const String ElementTitle = 'title';
}
