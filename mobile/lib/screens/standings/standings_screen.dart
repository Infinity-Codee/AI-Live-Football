/// Standings Screen — League tables

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/app_strings.dart';
import '../../services/api_service.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final _api = ApiService();
  int _selectedLeagueId = 39; // Premier League default
  List<Map<String, dynamic>> _standings = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  Future<void> _fetchStandings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getStandings(_selectedLeagueId);
      setState(() {
        _standings = List<Map<String, dynamic>>.from(data['standings'] ?? []);
      });
    } catch (_) {
      // Sentinel flag only — the UI renders the localized tr('standings.error').
      setState(() => _error = 'error');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>(); // rebuild on language switch
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Navigator.canPop(context)
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: AppTheme.white),
                              onPressed: () => Navigator.pop(context),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        tr('standings.title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // League selector
              _buildLeagueSelector(),
              // Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : _error != null
                        ? _buildError()
                        : _standings.isEmpty
                            ? Center(
                                child: Text(
                                  tr('standings.empty'),
                                  style: const TextStyle(color: AppTheme.grey),
                                ),
                              )
                            : _buildTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: AppTheme.grey),
          const SizedBox(height: 12),
          Text(
            tr('standings.error'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchStandings,
            icon: const Icon(Icons.refresh),
            label: Text(tr('home.retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSelector() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: AppConstants.popularLeagues.entries.map((e) {
          final isSelected = e.key == _selectedLeagueId;
          final leagueName = e.value['name']!;
          final leagueLogo = e.value['logo']!;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedLeagueId = e.key);
              _fetchStandings();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.bgCard,
                borderRadius: AppTheme.radiusSm,
                border: isSelected
                    ? null
                    : Border.all(color: AppTheme.bgSurface),
              ),
              child: Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: leagueLogo,
                    width: 20,
                    height: 20,
                    errorWidget: (_, __, ___) => const Icon(Icons.emoji_events, size: 20, color: AppTheme.greyLight),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    leagueName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.grey,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _standings.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader();
        final team = _standings[index - 1];
        return _buildRow(team, index);
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 28, child: Text('#', style: TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(child: Text(tr('standings.colTeam'), style: const TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 32, child: Text(tr('standings.colP'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 32, child: Text(tr('standings.colW'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 32, child: Text(tr('standings.colD'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 32, child: Text(tr('standings.colL'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.grey, fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 36, child: Text(tr('standings.colPts'), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> team, int index) {
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? AppTheme.bgCard : AppTheme.bgCard.withValues(alpha: 0.5),
        borderRadius: index == _standings.length
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${team['rank']}',
              style: TextStyle(
                color: team['rank'] <= 4 ? AppTheme.primary : AppTheme.greyLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if ((team['team_logo'] ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: team['team_logo'],
              width: 20,
              height: 20,
              errorWidget: (_, __, ___) => const SizedBox(width: 20),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              team['team_name'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 32, child: Text('${team['played']}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.greyLight, fontSize: 13))),
          SizedBox(width: 32, child: Text('${team['win']}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.green, fontSize: 13))),
          SizedBox(width: 32, child: Text('${team['draw']}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.draw, fontSize: 13))),
          SizedBox(width: 32, child: Text('${team['lose']}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.red, fontSize: 13))),
          SizedBox(
            width: 36,
            child: Text(
              '${team['points']}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
