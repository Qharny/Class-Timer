import 'package:flutter/material.dart';

class AssessmentItem {
  String name;
  double score; // Percentage (0-100)
  double weight; // Percentage (0-100)

  AssessmentItem({required this.name, this.score = 0, this.weight = 0});
}

class GradeCalculatorScreen extends StatefulWidget {
  const GradeCalculatorScreen({super.key});

  @override
  State<GradeCalculatorScreen> createState() => _GradeCalculatorScreenState();
}

class _GradeCalculatorScreenState extends State<GradeCalculatorScreen> {
  final List<AssessmentItem> _assessments = [
    AssessmentItem(name: 'Continuous Assessment', score: 0, weight: 40),
  ];

  double _examWeight = 60;
  double _targetGrade = 70; // Default target for 'A' or 'Pass'

  double get _currentAggregate {
    double total = 0;
    for (var item in _assessments) {
      total += (item.score / 100) * item.weight;
    }
    return total;
  }

  double get _requiredExamScore {
    double remaining = _targetGrade - _currentAggregate;
    if (remaining <= 0) return 0;
    return (remaining / _examWeight) * 100;
  }

  void _addItem() {
    setState(() {
      _assessments.add(AssessmentItem(name: 'New Assessment', weight: 10));
      _updateExamWeight();
    });
  }

  void _updateExamWeight() {
    double totalCaWeight = 0;
    for (var item in _assessments) {
      totalCaWeight += item.weight;
    }
    _examWeight = 100 - totalCaWeight;
    if (_examWeight < 0) _examWeight = 0;
  }

  void _onAssessmentValueChanged() {
    setState(_updateExamWeight);
  }

  @override
  Widget build(BuildContext context) {
    final requiredScore = _requiredExamScore;
    final isPossible = requiredScore <= 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Predictor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _assessments.clear();
              _assessments.add(AssessmentItem(name: 'CA', weight: 40));
              _updateExamWeight();
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPossible
                      ? [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ]
                      : [Colors.redAccent, Colors.red[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isPossible
                                ? Theme.of(context).primaryColor
                                : Colors.red)
                            .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Target Exam Score',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPossible
                        ? '${requiredScore.toStringAsFixed(1)}%'
                        : 'Impossible',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To achieve a final grade of ${_targetGrade.toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assessments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assessments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _assessments[index];
                return _AssessmentTile(
                  key: ObjectKey(item),
                  item: item,
                  onDelete: () => setState(() {
                    _assessments.removeAt(index);
                    _updateExamWeight();
                  }),
                  onValueChanged: _onAssessmentValueChanged,
                );
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Target Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildTargetControl(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetControl() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Target Final Grade'),
              Text(
                '${_targetGrade.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Slider(
            value: _targetGrade,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => _targetGrade = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exam Weight: ${_examWeight.toInt()}%',
                style: const TextStyle(color: Colors.grey),
              ),
              const Text('Total: 100%', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One assessment row. Owns its own TextEditingControllers so that editing
/// one row's score/weight — which needs to trigger a parent rebuild to
/// refresh the result card — doesn't recreate every row's controllers and
/// reset their cursor position, the way inline `TextEditingController(...)`
/// per rebuild would.
class _AssessmentTile extends StatefulWidget {
  final AssessmentItem item;
  final VoidCallback onDelete;
  final VoidCallback onValueChanged;

  const _AssessmentTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onValueChanged,
  });

  @override
  State<_AssessmentTile> createState() => _AssessmentTileState();
}

class _AssessmentTileState extends State<_AssessmentTile> {
  late final TextEditingController _nameController;
  late final TextEditingController _scoreController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _scoreController = TextEditingController(
      text: _formatNum(widget.item.score),
    );
    _weightController = TextEditingController(
      text: _formatNum(widget.item.weight),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _formatNum(double value) {
    if (value == 0) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: InputBorder.none,
                  ),
                  controller: _nameController,
                  onChanged: (v) => widget.item.name = v,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: _SmallField(
                  label: 'Score (%)',
                  hint: '0',
                  controller: _scoreController,
                  onChanged: (v) {
                    widget.item.score = double.tryParse(v) ?? 0;
                    widget.onValueChanged();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SmallField(
                  label: 'Weight (%)',
                  hint: 'Weight',
                  controller: _weightController,
                  onChanged: (v) {
                    widget.item.weight = double.tryParse(v) ?? 0;
                    widget.onValueChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SmallField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
