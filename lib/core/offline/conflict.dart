enum ConflictResolution { useLocal, useServer }

class BucketConflict {
  final String operationId;
  final String bucketType; // 'money' | 'investment' | 'charity'
  final double localValue;  // what the user set offline
  final double serverValue; // what's currently on the server

  const BucketConflict({
    required this.operationId,
    required this.bucketType,
    required this.localValue,
    required this.serverValue,
  });
}
