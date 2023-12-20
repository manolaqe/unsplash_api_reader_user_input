import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unspash API Reader with User Input',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Unspash API Reader with User Input'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _page = 1;
  final List<UnsplashPhoto> _photos = <UnsplashPhoto>[];
  bool isLoading = true;
  final ScrollController _controller = ScrollController();
  String searchText = '';
  String colorText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    _loadItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final double offset = _controller.offset;
    final double maxExtent = _controller.position.maxScrollExtent;

    if (!isLoading && offset > maxExtent * 0.8) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
    });

    final Client client = Client();

    final Uri uri = Uri.parse('https://api.unsplash.com/search/photos');

    final Response response = await client.get(
        uri.replace(queryParameters: <String, String>{
          'page': '$_page',
          'query': searchText
        }),
        headers: <String, String>{
          HttpHeaders.authorizationHeader:
              'Client-ID RyfFUy-CATYib_AafPmICQqaTuuri3qQzu93pcpZayg'
        });

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    for (final dynamic item in json['results'] as List<dynamic>) {
      _photos.add(UnsplashPhoto.fromJson(item as Map<String, dynamic>));
    }

    _page++;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                onSubmitted: (value) {
                  setState(() {
                    searchText = value;
                    _photos.clear();
                  });

                  _loadItems();
                },
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
            DropdownButton<String>(
              items: <String>[
                'black_and_white',
                'black',
                'white',
                'yellow',
                'orange',
                'red',
                'purple',
                'magenta',
                'green',
                'teal',
                'blue'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _photos.clear();
                  colorText = value!;
                });

                _loadItems();
              },
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (BuildContext buildContext) {
          return ListView.builder(
            controller: _controller,
            itemCount: _photos.length,
            itemBuilder: (BuildContext context, int index) {
              final UnsplashPhoto photo = _photos[index];
              return Column(
                children: <Widget>[
                  Image.network(
                    photo.urls!.regular!,
                    loadingBuilder: (BuildContext context, Widget widget,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return widget;
                      }

                      return Center(
                        child: CircularProgressIndicator(
                            value: loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!),
                      );
                    },
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(photo.user!.profileImage!.small!),
                    ),
                    title: Text(photo.user!.name!),
                    subtitle: Text(photo.description ?? ''),
                  ),
                  const SizedBox(
                    height: 20,
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class UnsplashPhoto {
  UnsplashPhoto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        width = json['width'] as int,
        height = json['height'] as int,
        color = json['color'] as String?,
        blurHash = json['blur_hash'] as String?,
        likes = json['likes'] as int,
        likedByUser = json['liked_by_user'] as bool,
        description = json['description'] as String?,
        user = User.fromJson(json['user'] as Map<String, dynamic>),
        currentUserCollections = (json['current_user_collections']
                as List<dynamic>)
            .map((dynamic i) => Collection.fromJson(i as Map<String, dynamic>))
            .toList(),
        urls = Urls.fromJson(json['urls'] as Map<String, dynamic>),
        links = Links.fromJson(json['links'] as Map<String, dynamic>);
  final String? id;
  final String? createdAt;
  final String? updatedAt;
  final int? width;
  final int? height;
  final String? color;
  final String? blurHash;
  final int? likes;
  final bool? likedByUser;
  final String? description;
  final User? user;
  final List<Collection> currentUserCollections;
  final Urls? urls;
  final Links? links;
}

class User {
  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        username = json['username'] as String?,
        name = json['name'] as String?,
        portfolioUrl = json['portfolio_url'] as String?,
        bio = json['bio'] as String?,
        location = json['location'] as String?,
        totalLikes = json['total_likes'] as int,
        totalPhotos = json['total_photos'] as int,
        totalCollections = json['total_collections'] as int,
        instagramUsername = json['instagram_username'] as String?,
        twitterUsername = json['twitter_username'] as String?,
        profileImage = ProfileImage.fromJson(
            json['profile_image'] as Map<String, dynamic>),
        links = UserLinks.fromJson(json['links'] as Map<String, dynamic>);
  final String? id;
  final String? username;
  final String? name;
  final String? portfolioUrl;
  final String? bio;
  final String? location;
  final int? totalLikes;
  final int? totalPhotos;
  final int? totalCollections;
  final String? instagramUsername;
  final String? twitterUsername;
  final ProfileImage? profileImage;
  final UserLinks? links;
}

class ProfileImage {
  ProfileImage.fromJson(Map<String, dynamic> json)
      : small = json['small'] as String?,
        medium = json['medium'] as String?,
        large = json['large'] as String?;
  final String? small;
  final String? medium;
  final String? large;
}

class UserLinks {
  UserLinks.fromJson(Map<String, dynamic> json)
      : self = json['self'] as String?,
        html = json['html'] as String?,
        photos = json['photos'] as String?,
        likes = json['likes'] as String?,
        portfolio = json['portfolio'] as String?;
  final String? self;
  final String? html;
  final String? photos;
  final String? likes;
  final String? portfolio;
}

class Links {
  Links.fromJson(Map<String, dynamic> json)
      : self = json['self'] as String?,
        html = json['html'] as String?,
        download = json['download'] as String?,
        downloadLocation = json['download_location'] as String?;
  final String? self;
  final String? html;
  final String? download;
  final String? downloadLocation;
}

class Collection {
  Collection.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String?,
        publishedAt = json['published_at'] as String?,
        lastCollectedAt = json['last_collected_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        coverPhoto = json['cover_photo'],
        user = json['user'];
  final int? id;
  final String? title;
  final String? publishedAt;
  final String? lastCollectedAt;
  final String? updatedAt;
  final dynamic coverPhoto;
  final dynamic user;
}

class Urls {
  Urls.fromJson(Map<String, dynamic> json)
      : raw = json['raw'] as String?,
        full = json['full'] as String?,
        regular = json['regular'] as String?,
        small = json['small'] as String?,
        thumb = json['thumb'] as String?;
  final String? raw;
  final String? full;
  final String? regular;
  final String? small;
  final String? thumb;
}
