import 'package:cloud_firestore/cloud_firestore.dart';

class TecnicosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> listarTecnicos() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'tecnico')
        .snapshots();
  }
}
