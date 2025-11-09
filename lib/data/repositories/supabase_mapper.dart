Map<String, dynamic> mapRow(dynamic row) {
  if (row == null) {
    throw const FormatException('Supabase row is null');
  }
  if (row is Map<String, dynamic>) {
    return row;
  }
  if (row is Map) {
    return Map<String, dynamic>.from(row);
  }
  throw FormatException('Unsupported Supabase row type: ${row.runtimeType}');
}

List<Map<String, dynamic>> mapRows(dynamic rows) {
  if (rows == null) {
    return const [];
  }
  if (rows is List) {
    return rows.map(mapRow).toList(growable: false);
  }
  return [mapRow(rows)];
}
