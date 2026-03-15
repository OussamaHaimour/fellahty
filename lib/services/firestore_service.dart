import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/equipment_model.dart';
import '../models/rental_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER OPERATIONS ---
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromDocument(doc);
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromDocument(doc);
      return null;
    });
  }

  Future<void> updateUserWallet(String uid, double newBalance) async {
    await _db.collection('users').doc(uid).update({'walletBalance': newBalance});
  }

  Future<void> rateWorker(String workerId, double newScore) async {
    await _db.collection('users').doc(workerId).update({'score': newScore});
  }

  // --- JOB OPERATIONS ---
  Future<void> createJob(Job job) async {
    await _db.collection('jobs').doc(job.id).set(job.toMap());
  }

  Stream<List<Job>> getOpenJobs() {
    return _db.collection('jobs').where('status', isEqualTo: 'open').snapshots()
        .map((s) => s.docs.map((d) => Job.fromDocument(d)).toList());
  }

  Stream<List<Job>> getJobsByFarmer(String farmerId) {
    return _db.collection('jobs').where('farmerId', isEqualTo: farmerId).snapshots()
        .map((s) => s.docs.map((d) => Job.fromDocument(d)).toList());
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await _db.collection('jobs').doc(jobId).update({'status': status});
  }

  Future<int> countJobsByFarmer(String farmerId) async {
    final s = await _db.collection('jobs').where('farmerId', isEqualTo: farmerId).where('status', isEqualTo: 'open').get();
    return s.docs.length;
  }

  Future<int> countApplicationsForFarmer(String farmerId) async {
    final jobsSnap = await _db.collection('jobs').where('farmerId', isEqualTo: farmerId).get();
    int total = 0;
    for (var job in jobsSnap.docs) {
      final appSnap = await _db.collection('applications').where('jobId', isEqualTo: job.id).where('status', isEqualTo: 'pending').get();
      total += appSnap.docs.length;
    }
    return total;
  }

  Future<int> countAcceptedJobsForWorker(String workerId) async {
    final s = await _db.collection('applications').where('workerId', isEqualTo: workerId).where('status', isEqualTo: 'accepted').get();
    return s.docs.length;
  }

  Future<double> getWorkerScore(String workerId) async {
    final user = await getUser(workerId);
    return user?.score ?? 0.0;
  }

  // --- APPLICATION OPERATIONS ---
  Future<void> applyToJob(Application application) async {
    await _db.collection('applications').doc(application.id).set(application.toMap());
  }

  Stream<List<Application>> getApplicationsForJob(String jobId) {
    return _db.collection('applications').where('jobId', isEqualTo: jobId).snapshots()
        .map((s) => s.docs.map((d) => Application.fromDocument(d)).toList());
  }

  Stream<List<Application>> getApplicationsByWorker(String workerId) {
    return _db.collection('applications').where('workerId', isEqualTo: workerId).snapshots()
        .map((s) => s.docs.map((d) => Application.fromDocument(d)).toList());
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    await _db.collection('applications').doc(applicationId).update({'status': status});
  }

  /// Worker finishes job
  Future<void> completeApplication(String applicationId) async {
    await updateApplicationStatus(applicationId, 'completed');
  }

  /// Farmer confirms payment for the entire job
  Future<void> payWorker(
    String applicationId, String workerId, String farmerId,
    double totalSalary, double rating,
  ) async {
    double appCommission = totalSalary > 100 ? (totalSalary * 0.15) : 20.0;
    double workerTakeHome = totalSalary - appCommission;

    await _db.runTransaction((transaction) async {
      DocumentReference farmerRef = _db.collection('users').doc(farmerId);
      DocumentReference workerRef = _db.collection('users').doc(workerId);
      DocumentReference appRef = _db.collection('applications').doc(applicationId);

      DocumentSnapshot farmerDoc = await transaction.get(farmerRef);
      DocumentSnapshot workerDoc = await transaction.get(workerRef);
      
      double farmerBalance = (farmerDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      double workerBalance = (workerDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      if (farmerBalance < totalSalary) throw Exception("Insufficient balance");

      transaction.update(farmerRef, {'walletBalance': farmerBalance - totalSalary});
      transaction.update(workerRef, {'walletBalance': workerBalance + workerTakeHome});
      transaction.update(appRef, {'status': 'paid'});

      // Log commission
      DocumentReference commRef = _db.collection('commissions').doc();
      transaction.set(commRef, {
        'amount': appCommission,
        'sourceId': applicationId,
        'type': 'job_full',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update rating
      double currentScore = (workerDoc.data() as Map<String, dynamic>)['score'] ?? 0.0;
      transaction.update(workerRef, {'score': (currentScore + rating) / 2});
    });
  }

  // --- EQUIPMENT OPERATIONS ---
  Future<void> addEquipment(Equipment equipment) async {
    await _db.collection('equipment').doc(equipment.id).set(equipment.toMap());
  }

  Stream<List<Equipment>> getAllEquipment() {
    return _db.collection('equipment').snapshots()
        .map((s) => s.docs.map((d) => Equipment.fromDocument(d)).toList());
  }

  Stream<List<Equipment>> getAllAvailableEquipment() {
    return _db.collection('equipment').where('isAvailable', isEqualTo: true).snapshots()
        .map((s) => s.docs.map((d) => Equipment.fromDocument(d)).toList());
  }

  Stream<List<Equipment>> getEquipmentByOwner(String ownerId) {
    return _db.collection('equipment').where('ownerId', isEqualTo: ownerId).snapshots()
        .map((s) => s.docs.map((d) => Equipment.fromDocument(d)).toList());
  }

  // --- RENTAL OPERATIONS ---
  Future<void> requestRental(EquipmentRental rental) async {
    await _db.collection('rentals').doc(rental.id).set(rental.toMap());
  }

  Stream<List<EquipmentRental>> getRentalsByOwner(String ownerId) {
    return _db.collection('rentals').where('ownerId', isEqualTo: ownerId).snapshots()
        .map((s) => s.docs.map((d) => EquipmentRental.fromDocument(d)).toList());
  }

  Stream<List<EquipmentRental>> getRentalsByRenter(String renterId) {
    return _db.collection('rentals').where('renterId', isEqualTo: renterId).snapshots()
        .map((s) => s.docs.map((d) => EquipmentRental.fromDocument(d)).toList());
  }

  Future<void> updateRentalStatus(String rentalId, String status) async {
    await _db.collection('rentals').doc(rentalId).update({'status': status});
  }

  /// Owner finishes rental
  Future<void> completeRental(String rentalId) async {
    await updateRentalStatus(rentalId, 'completed');
  }

  /// Farmer confirms rental payment
  Future<void> payEquipmentOwner(
    String rentalId, String ownerId, String renterId,
    double totalPrice, double rating,
  ) async {
    double appCommission = totalPrice < 100 ? 20.0 : (totalPrice * 0.15);
    double ownerTakeHome = totalPrice - appCommission;

    await _db.runTransaction((transaction) async {
      DocumentReference renterRef = _db.collection('users').doc(renterId);
      DocumentReference ownerRef = _db.collection('users').doc(ownerId);
      DocumentReference rentalRef = _db.collection('rentals').doc(rentalId);

      DocumentSnapshot renterDoc = await transaction.get(renterRef);
      DocumentSnapshot ownerDoc = await transaction.get(ownerRef);

      double renterBalance = (renterDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      double ownerBalance = (ownerDoc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0;
      if (renterBalance < totalPrice) throw Exception("Insufficient balance");

      transaction.update(renterRef, {'walletBalance': renterBalance - totalPrice});
      transaction.update(ownerRef, {'walletBalance': ownerBalance + ownerTakeHome});
      transaction.update(rentalRef, {'status': 'paid'});

      // Log commission
      DocumentReference commRef = _db.collection('commissions').doc();
      transaction.set(commRef, {
        'amount': appCommission,
        'sourceId': rentalId,
        'type': 'rental_full',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update rating
      double currentScore = (ownerDoc.data() as Map<String, dynamic>)['score'] ?? 0.0;
      transaction.update(ownerRef, {'score': (currentScore + rating) / 2});
    });
  }

  // --- DELETE / CANCEL OPERATIONS ---

  /// Farmer deletes a job (and its applications)
  Future<void> deleteJob(String jobId) async {
    // Delete all applications for this job
    final apps = await _db.collection('applications').where('jobId', isEqualTo: jobId).get();
    for (var doc in apps.docs) {
      await doc.reference.delete();
    }
    await _db.collection('jobs').doc(jobId).delete();
  }

  /// Worker cancels a pending application
  Future<void> cancelApplication(String applicationId) async {
    await _db.collection('applications').doc(applicationId).delete();
  }

  /// Farmer cancels a pending rental request
  Future<void> cancelRental(String rentalId) async {
    await _db.collection('rentals').doc(rentalId).delete();
  }

  /// Equipment owner deletes their equipment
  Future<void> deleteEquipment(String equipmentId) async {
    // Delete related rentals
    final rentals = await _db.collection('rentals').where('equipmentId', isEqualTo: equipmentId).get();
    for (var doc in rentals.docs) {
      await doc.reference.delete();
    }
    await _db.collection('equipment').doc(equipmentId).delete();
  }

  // --- ADMIN OPERATIONS ---

  /// Admin: get all users
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromDocument(d)).toList());
  }

  /// Admin: get all jobs
  Stream<List<Job>> getAllJobs() {
    return _db.collection('jobs').snapshots()
        .map((s) => s.docs.map((d) => Job.fromDocument(d)).toList());
  }

  /// Admin: get all applications
  Stream<List<Application>> getAllApplications() {
    return _db.collection('applications').snapshots()
        .map((s) => s.docs.map((d) => Application.fromDocument(d)).toList());
  }

  /// Admin: get all rentals
  Stream<List<EquipmentRental>> getAllRentals() {
    return _db.collection('rentals').snapshots()
        .map((s) => s.docs.map((d) => EquipmentRental.fromDocument(d)).toList());
  }

  /// Admin: ban/unban a user
  Future<void> toggleUserBan(String userId, bool banned) async {
    await _db.collection('users').doc(userId).update({'banned': banned});
  }

  /// Admin: delete a single document from any collection
  Future<void> adminDeleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }
}
