class CourseModel {
  String id;
  String name;
  int credit;
  String grade; // AA, BA vb.

  CourseModel({this.id = '', required this.name, required this.credit, required this.grade});

  // Notu sayıya çevirme (4.0 üzerinden)
  double get numericGrade {
    switch (grade) {
      case 'AA': return 4.0;
      case 'BA': return 3.5;
      case 'BB': return 3.0;
      case 'CB': return 2.5;
      case 'CC': return 2.0;
      case 'DC': return 1.5;
      case 'DD': return 1.0;
      default: return 0.0;
    }
  }
}