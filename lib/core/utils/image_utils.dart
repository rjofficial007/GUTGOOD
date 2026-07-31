String getDynamicImageUrl(String? keyword) {
  final query = (keyword ?? 'healthy food').trim();
  if (query.isEmpty) return 'https://placehold.co/400x400/EEE/31343C?text=No+Image';
  return 'https://tse2.mm.bing.net/th?q=${Uri.encodeComponent(query)}&w=400&h=400&c=7&rs=1&p=0&dpr=2&pid=1.7';
}
