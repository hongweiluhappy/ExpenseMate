class JobPost {
  final String id;
  final String title;      // e.g.: Moving helper, Temporary photography
  final String pay;        // e.g.: $20/h or $50 Fixed
  final String contact;    // Contact(Email/WeChat/Phone)
  final String location;   // Campus/Somewhere in city
  final String desc;       // Brief description
  final DateTime createdAt;

  JobPost({
    required this.id,
    required this.title,
    required this.pay,
    required this.contact,
    required this.location,
    required this.desc,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'pay': pay, 'contact': contact,
    'location': location, 'desc': desc, 'created_at': createdAt.toIso8601String(),
  };

  static JobPost fromJson(Map<String, dynamic> m) => JobPost(
    id: m['id'],
    title: m['title'],
    pay: m['pay'],
    contact: m['contact'],
    location: m['location'],
    desc: m['desc'],
    createdAt: DateTime.parse(m['created_at']),
  );
}