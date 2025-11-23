import 'package:intl/intl.dart';

class ServiceRequest {
  final String id;
  final String requesterId;
  final String travelerId;
  final String tripId;
  final String serviceType; // 'Pabakal' or 'Pasabay'
  final String status; // 'Pending', 'Accepted', 'Rejected', 'Completed', 'Cancelled'
  
  // Common fields
  final String? pickupLocation;
  final String? dropoffLocation;
  final DateTime? pickupTime;
  
  // Pabakal specific
  final String? productName;
  final String? storeName;
  final String? storeLocation;
  final double? productCost;
  final String? productDescription;
  
  // Pasabay specific
  final String? recipientName;
  final String? recipientPhone;
  final String? packageDescription;
  
  // Attachments
  final List<String>? photoUrls;
  final List<String>? documentUrls;
  
  // Payment
  final double serviceFee;
  final double totalAmount;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String? rejectionReason;

  ServiceRequest({
    required this.id,
    required this.requesterId,
    required this.travelerId,
    required this.tripId,
    required this.serviceType,
    required this.status,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupTime,
    this.productName,
    this.storeName,
    this.storeLocation,
    this.productCost,
    this.productDescription,
    this.recipientName,
    this.recipientPhone,
    this.packageDescription,
    this.photoUrls,
    this.documentUrls,
    required this.serviceFee,
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.rejectionReason,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      travelerId: json['traveler_id'] as String,
      tripId: json['trip_id'] as String,
      serviceType: json['service_type'] as String,
      status: json['status'] as String,
      pickupLocation: json['pickup_location'] as String?,
      dropoffLocation: json['dropoff_location'] as String?,
      pickupTime: json['pickup_time'] != null 
          ? DateTime.parse(json['pickup_time'] as String) 
          : null,
      productName: json['product_name'] as String?,
      storeName: json['store_name'] as String?,
      storeLocation: json['store_location'] as String?,
      productCost: json['product_cost'] != null 
          ? (json['product_cost'] as num).toDouble() 
          : null,
      productDescription: json['product_description'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      packageDescription: json['package_description'] as String?,
      photoUrls: json['photo_urls'] != null 
          ? List<String>.from(json['photo_urls'] as List) 
          : null,
      documentUrls: json['document_urls'] != null 
          ? List<String>.from(json['document_urls'] as List) 
          : null,
      serviceFee: (json['service_fee'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'traveler_id': travelerId,
      'trip_id': tripId,
      'service_type': serviceType,
      'status': status,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_time': pickupTime?.toIso8601String(),
      'product_name': productName,
      'store_name': storeName,
      'store_location': storeLocation,
      'product_cost': productCost,
      'product_description': productDescription,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'package_description': packageDescription,
      'photo_urls': photoUrls,
      'document_urls': documentUrls,
      'service_fee': serviceFee,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'rejection_reason': rejectionReason,
    };
  }

  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt);
  }

  String get formattedPickupTime {
    if (pickupTime == null) return 'Not specified';
    return DateFormat('hh:mm a').format(pickupTime!);
  }
}

