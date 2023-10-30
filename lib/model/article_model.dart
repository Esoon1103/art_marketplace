class ArticleModel{
  final String articleID;
  final String name;
  final String location;
  String image;
  final String date;
  final String description;

  ArticleModel({
    required this.articleID,
    required this.name,
    required this.location,
    required this.image,
    required this.date,
    required this.description,
  });
}