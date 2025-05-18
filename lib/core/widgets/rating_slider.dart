import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// A slider for rating items from 1 to 5
class RatingSlider extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;
  final bool showLabels;
  final String? title;
  final String? subtitle;
  
  const RatingSlider({
    Key? key,
    this.initialValue = 3.0,
    required this.onChanged,
    this.showLabels = true,
    this.title,
    this.subtitle,
  }) : assert(initialValue >= 1 && initialValue <= 5, 'Rating must be between 1 and 5'),
       super(key: key);
  
  @override
  State<RatingSlider> createState() => _RatingSliderState();
}

class _RatingSliderState extends State<RatingSlider> {
  late double _rating;
  
  @override
  void initState() {
    super.initState();
    _rating = widget.initialValue;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
        ],
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getColorForRating(_rating),
                inactiveTrackColor: Colors.grey[300],
                trackShape: RoundedRectSliderTrackShape(),
                trackHeight: 8.0,
                thumbColor: _getColorForRating(_rating),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayColor: _getColorForRating(_rating).withAlpha(32),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 20.0),
              ),
              child: Slider(
                value: _rating,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                  widget.onChanged(value);
                },
              ),
            ),
            if (widget.showLabels)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ratingLabel(1),
                    _ratingLabel(2),
                    _ratingLabel(3),
                    _ratingLabel(4),
                    _ratingLabel(5),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _ratingLabel(int rating) {
    final bool isSelected = _rating.round() == rating;
    
    return Column(
      children: [
        Text(
          rating.toString(),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? _getColorForRating(rating.toDouble()) : Colors.grey[600],
          ),
        ),
        if (widget.showLabels) ...[
          SizedBox(height: 4),
          Text(
            AppConstants.ratingDescriptions[rating] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? _getColorForRating(rating.toDouble()) : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
  
  Color _getColorForRating(double rating) {
    if (rating <= 1.0) {
      return Colors.red;
    } else if (rating <= 2.0) {
      return Colors.orange;
    } else if (rating <= 3.0) {
      return Colors.amber;
    } else if (rating <= 4.0) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
}
