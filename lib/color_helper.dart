class AppColorsData {
  static final Map<String, String> colorMap = {
    // --- Primary & Most Popular Colors ---
    '#000000': 'Black',
    '#FFFFFF': 'White',
    '#FF0000': 'Red',
    '#0000FF': 'Blue',
    '#008000': 'Green',
    '#FFFF00': 'Yellow',
    '#FFA500': 'Orange',
    '#800080': 'Purple',
    '#808080': 'Grey',
    '#A52A2A': 'Brown',

    // --- Nude, Beige & Earth Tones ---
    '#F5F5DC': 'Beige / Cashmere',
    '#D2B48C': 'Tan',
    '#C4A482': 'Desert Sand',
    '#E3DAC9': 'Antique White',
    '#FAF0E6': 'Linen',
    '#FFF8DC': 'Cornsilk',
    '#FDF5E6': 'Old Lace',
    '#E5AA70': 'Fawn',
    '#C8AD7F': 'Champagne',
    '#483C32': 'Taupe',

    // --- Pinks, Purples & Feminine Shades ---
    '#FFC0CB': 'Pink',
    '#FF69B4': 'Hot Pink',
    '#FF1493': 'Deep Pink',
    '#DB7093': 'Pale Violet Red',
    '#FFB6C1': 'Light Pink',
    '#E6E6FA': 'Lavender',
    '#D8BFD8': 'Thistle',
    '#DDA0DD': 'Plum',
    '#BA55D3': 'Medium Orchid',

    // --- Blues & Aquas ---
    '#00FFFF': 'Cyan / Aqua',
    '#87CEEB': 'Sky Blue',
    '#4682B4': 'Steel Blue',
    '#000080': 'Navy Blue',
    '#1E90FF': 'Dodger Blue',
    '#5F9EA0': 'Cadet Blue',
    '#008B8B': 'Dark Cyan',

    // --- Greens ---
    '#00FF00': 'Lime Green',
    '#32CD32': 'Lime',
    '#98FB98': 'Pale Green',
    '#2E8B57': 'Sea Green',
    '#556B2F': 'Dark Olive Green',
    '#006400': 'Dark Green',

    // --- Reds, Maroons & Burgundies ---
    '#800000': 'Maroon',
    '#800020': 'Burgundy',
    '#DC143C': 'Crimson',
    '#B22222': 'Firebrick',
    '#CD5C5C': 'Indian Red',

    // --- Metallics, Silvers & Golds ---
    '#C0C0C0': 'Silver',
    '#FFD700': 'Gold',
    '#B8860B': 'Dark Goldenrod',
    '#708090': 'Slate Grey',
    '#36454F': 'Charcoal',
    '#2F4F4F': 'Dark Slate Grey',
  };

  static String getColorName(String hexCode) {
    if (hexCode.isEmpty) return 'Default Color';
    
    String normalizedCode = hexCode.trim().toUpperCase();
    return colorMap[normalizedCode] ?? hexCode;
  }
}