# More dish photos for Pantry

83 of the 103 recipes in the built-in recipe book have no dish photo yet, so they show the ingredient tile. These prompts cover all of them, in the same style as the first 15 photos in [asset-prompts.md](asset-prompts.md).

**How to make them**
1. In ChatGPT image generation, paste the **style line** first, then one dish line. Always ask for **3:2 landscape**.
2. Save each image with the **exact file name** shown (PNG or JPG) in one folder.
3. Hand the folder to Claude. Claude adds the images to `Assets.xcassets/Photos` and adds the "Shows on titles with" words to `RecipeArt`, so a recipe gets a photo whenever its title names that dish. That includes recipes Apple Intelligence writes.

Do Part 1 first: those dishes come up most often, from the book and from Apple Intelligence. You can stop at any point; dishes without a photo keep the ingredient tile.

**Style line (paste before every dish):**

> Professional food delivery app photography, appetizing, natural soft daylight, shallow depth of field, clean light warm-gray background, crisp detail, no text, no logos, no hands, no people. 3:2 landscape.

## Part 1. Most common dishes (25)

| File name | Shows on titles with | Dish |
|---|---|---|
| `dish-scrambled-eggs` | scrambled egg | Soft creamy scrambled eggs on a slice of buttered toast, chives on top, white plate, 45-degree angle. |
| `dish-garlic-pasta` | garlic butter pasta, garlic pasta, aglio | Spaghetti tossed in garlic butter with parsley and chili flakes in a shallow bowl, 45-degree angle. |
| `dish-pesto-pasta` | pesto | Penne in bright green basil pesto with pine nuts and parmesan shavings in a white bowl, top-down. |
| `dish-mushroom-pasta` | mushroom pasta, mushroom fettuccine | Fettuccine in a creamy mushroom sauce with thyme and black pepper in a shallow bowl, 45-degree angle. |
| `dish-mac-cheese` | mac and cheese, mac & cheese, macaroni | Creamy stovetop macaroni and cheese in a small pot with a wooden spoon, cheese pulling, 45-degree angle. |
| `dish-stir-fry` | chicken stir-fry, chicken & broccoli, chicken and broccoli | Chicken and broccoli stir-fry with glossy sauce and sesame seeds in a dark wok, 45-degree angle. |
| `dish-quesadilla` | quesadilla | A golden chicken and cheese quesadilla cut into wedges, salsa and sour cream on the side, top-down. |
| `dish-avocado-toast` | avocado toast | Avocado toast on sourdough topped with a fried egg and chili flakes, white plate, 45-degree angle. |
| `dish-tomato-soup` | tomato soup | A bowl of smooth tomato soup with a swirl of cream and basil, grilled bread on the side, top-down. |
| `dish-lentil-soup` | lentil soup, dal soup | A rustic bowl of lentil soup with carrots and a lemon wedge, crusty bread beside it, 45-degree angle. |
| `dish-chickpea-curry` | chickpea curry, chana masala | Chickpea curry in a red-orange sauce with rice and cilantro in a wide bowl, top-down. |
| `dish-butter-chicken` | butter chicken, chicken tikka | Butter chicken in a creamy orange sauce with naan and basmati rice, top-down. |
| `dish-french-toast` | french toast | A stack of cinnamon French toast with powdered sugar, berries and maple syrup, 45-degree angle. |
| `dish-burger` | burger, cheeseburger | A classic cheeseburger with lettuce, tomato and melted cheddar on a sesame bun, fries beside it, eye level. |
| `dish-blt` | blt, bacon sandwich | A BLT sandwich on toasted bread cut in half, crispy bacon visible, on a wooden board, 45-degree angle. |
| `dish-pizza` | pizza, margherita | A margherita pizza with fresh mozzarella, basil and blistered crust on a wooden peel, top-down. |
| `dish-chicken-parm` | chicken parmesan, chicken parm | Breaded chicken parmesan with melted mozzarella and marinara over spaghetti, 45-degree angle. |
| `dish-burrito-bowl` | burrito bowl, burrito | A burrito bowl with seasoned beef, rice, black beans, corn, pico de gallo and lime, top-down. |
| `dish-noodles` | sesame noodles, peanut noodles, lo mein, yakisoba | Stir-fried noodles with vegetables, sesame seeds and green onions in a bowl with chopsticks, 45-degree angle. |
| `dish-pad-thai` | pad thai | Pad thai with shrimp, crushed peanuts, bean sprouts and a lime wedge on a plate, 45-degree angle. |
| `dish-beef-broccoli` | beef and broccoli, beef & broccoli | Beef and broccoli in a glossy brown sauce over white rice in a bowl, 45-degree angle. |
| `dish-shakshuka` | shakshuka | Shakshuka in a cast-iron pan: eggs poached in spiced tomato sauce with feta and parsley, top-down. |
| `dish-fajitas` | fajita | Sizzling shrimp fajitas with peppers and onions in a cast-iron skillet, tortillas on the side, 45-degree angle. |
| `dish-loaded-potato` | baked potato, loaded potato | A loaded baked potato with sour cream, cheddar, bacon bits and chives on a plate, 45-degree angle. |
| `dish-guacamole` | guacamole | Chunky guacamole in a stone bowl with tortilla chips and lime around it, top-down. |

## Part 2. The rest of the recipe book (58)

| File name | Shows on titles with | Dish |
|---|---|---|
| `dish-tuna-melt` | tuna melt | An open-faced tuna melt with bubbling cheddar on toasted bread, 45-degree angle. |
| `dish-caprese` | caprese | Caprese salad: alternating tomato and mozzarella slices with basil and olive oil on a white platter, top-down. |
| `dish-sheet-pan` | sheet pan | Sheet pan roasted sausage with peppers, onions and potatoes on a baking tray, top-down. |
| `dish-teriyaki-bowl` | teriyaki | Teriyaki tofu cubes over rice with broccoli and sesame seeds in a bowl, 45-degree angle. |
| `dish-parfait` | parfait | A yogurt parfait in a glass with granola and mixed berries, eye level. |
| `dish-pb-toast` | peanut butter | Peanut butter toast topped with banana slices and a drizzle of honey on a plate, top-down. |
| `dish-huevos-rancheros` | huevos rancheros | Huevos rancheros: fried eggs on tortillas with ranchero sauce, beans and avocado, top-down. |
| `dish-chilaquiles` | chilaquiles | Chilaquiles rojos with red salsa, a fried egg, crema, queso fresco and onion in a skillet, top-down. |
| `dish-street-corn` | elote, street corn | Grilled Mexican street corn on the cob with mayo, cotija, chili powder and lime, 45-degree angle. |
| `dish-enchiladas` | enchilada | Cheese enchiladas in red sauce with melted cheese and cilantro in a baking dish, top-down. |
| `dish-risotto` | risotto | Creamy lemon parmesan risotto in a shallow bowl with parmesan shavings and lemon zest, 45-degree angle. |
| `dish-bruschetta` | bruschetta | Tomato bruschetta with basil on toasted baguette slices on a wooden board, 45-degree angle. |
| `dish-eggplant-parm` | eggplant parmesan, eggplant parm | Eggplant parmesan with layered marinara and melted mozzarella in a baking dish, a slice lifted out, 45-degree angle. |
| `dish-sausage-peppers` | sausage and peppers, sausage & peppers | Italian sausages with sautéed bell peppers and onions in a cast-iron skillet, top-down. |
| `dish-piccata` | piccata | Chicken piccata with lemon caper butter sauce and parsley on a white plate, 45-degree angle. |
| `dish-breakfast-hash` | hash | A sausage and potato breakfast hash in a skillet topped with two sunny-side-up eggs, top-down. |
| `dish-biscuits-gravy` | biscuits, gravy | Split buttermilk biscuits smothered in sausage gravy with black pepper on a plate, 45-degree angle. |
| `dish-meatloaf` | meatloaf | Slices of glazed meatloaf with mashed potatoes and green beans on a plate, 45-degree angle. |
| `dish-mapo-tofu` | mapo tofu | Mapo tofu in a red chili sauce with ground pork and green onions in a bowl, rice beside it, top-down. |
| `dish-tomato-egg` | tomato and egg, tomato & egg | Chinese tomato and egg stir-fry with green onions over rice in a bowl, 45-degree angle. |
| `dish-kung-pao` | kung pao | Kung pao chicken with peanuts, dried chilies and green onions in a wok, 45-degree angle. |
| `dish-sweet-sour` | sweet and sour, sweet & sour | Sweet and sour pork with pineapple and bell peppers in a glossy red sauce on a plate, 45-degree angle. |
| `dish-oyakodon` | oyakodon | Oyakodon: chicken and soft egg simmered with onion over rice in a donburi bowl, top-down. |
| `dish-gyudon` | gyudon, beef bowl | Gyudon: thin-sliced simmered beef and onion over rice with pickled ginger in a bowl, 45-degree angle. |
| `dish-katsu` | katsu | Sliced golden chicken katsu with shredded cabbage, rice and katsu sauce on a plate, 45-degree angle. |
| `dish-shogayaki` | shogayaki, ginger pork | Pork shogayaki: ginger-glazed pork slices with shredded cabbage and rice on a plate, 45-degree angle. |
| `dish-tamagoyaki` | tamagoyaki | Sliced tamagoyaki rolled omelette on a rice bowl with green onions, 45-degree angle. |
| `dish-bibimbap` | bibimbap | Bibimbap in a stone bowl: rice topped with vegetables, beef, a fried egg and gochujang, top-down. |
| `dish-bulgogi` | bulgogi | Beef bulgogi with sesame seeds and green onions, rice and kimchi on the side, 45-degree angle. |
| `dish-korean-chicken` | korean fried chicken | Crispy Korean fried chicken glazed in red gochujang sauce with sesame seeds, 45-degree angle. |
| `dish-japchae` | japchae | Japchae glass noodles with vegetables, beef and sesame seeds on a plate, 45-degree angle. |
| `dish-steamed-egg` | gyeran-jjim, steamed egg | Korean steamed egg puffed up in a small black earthenware pot with green onions, 45-degree angle. |
| `dish-spicy-pork` | spicy pork | Spicy Korean pork stir-fry in red sauce with onions and green onions, rice on the side, 45-degree angle. |
| `dish-basil-chicken` | basil chicken, pad kra pao | Thai basil chicken with a crispy fried egg over jasmine rice on a plate, top-down. |
| `dish-noodle-salad` | noodle salad, bun | Vietnamese rice noodle salad with herbs, cucumber, carrots, peanuts and nuoc cham in a bowl, top-down. |
| `dish-tom-kha` | tom kha | Tom kha coconut soup with shrimp, mushrooms, lemongrass and cilantro in a bowl, 45-degree angle. |
| `dish-pho` | pho | A bowl of beef pho with rice noodles, thin beef slices, herbs, bean sprouts and lime, top-down. |
| `dish-aloo-gobi` | aloo gobi | Aloo gobi: turmeric-spiced potatoes and cauliflower with cilantro in a bowl, 45-degree angle. |
| `dish-saag` | saag | Saag with tofu cubes in a creamy spinach sauce with naan on the side, top-down. |
| `dish-dal` | dal | Yellow dal tadka with a ghee and cumin drizzle, rice beside it, top-down. |
| `dish-egg-curry` | egg curry | Egg curry: halved boiled eggs in a spiced tomato-onion gravy with cilantro in a bowl, 45-degree angle. |
| `dish-coconut-curry` | coconut curry, shrimp curry | Coconut shrimp curry in a creamy yellow sauce with rice and lime, top-down. |
| `dish-hummus` | hummus | A swirl of hummus with olive oil, paprika and chickpeas in a bowl, warm pita beside it, top-down. |
| `dish-shawarma` | shawarma | Chicken shawarma pitas with tomato, cucumber and garlic sauce on a board, 45-degree angle. |
| `dish-baba-ganoush` | baba ganoush | Baba ganoush with olive oil, pomegranate seeds and parsley in a bowl, pita on the side, top-down. |
| `dish-tabbouleh` | tabbouleh | Couscous tabbouleh with parsley, tomato, cucumber and lemon in a bowl, top-down. |
| `dish-ratatouille` | ratatouille | Ratatouille with zucchini, eggplant and tomato in a cast-iron pan, top-down. |
| `dish-onion-soup` | onion soup | French onion soup in a crock with a bubbling, browned cheese crust, 45-degree angle. |
| `dish-gratin` | gratin | Potato gratin in a baking dish with a golden, bubbling top, a portion scooped out, 45-degree angle. |
| `dish-squash-soup` | squash soup, pumpkin soup | Butternut squash soup with a cream swirl and toasted pumpkin seeds in a bowl, top-down. |
| `dish-bean-soup` | black bean soup, bean soup | Smoky black bean soup topped with sour cream, avocado and cilantro in a bowl, top-down. |
| `dish-chowder` | chowder | Potato corn chowder with bacon bits and chives in a bowl, crackers on the side, 45-degree angle. |
| `dish-cucumber-salad` | cucumber salad | Smashed cucumber salad with chili oil, garlic and sesame seeds on a plate, top-down. |
| `dish-bread-salad` | bread salad, panzanella | Tomato bread salad with torn toasted bread, basil and red onion in a bowl, top-down. |
| `dish-kale-salad` | kale salad | Kale and apple salad with walnuts and shaved parmesan in a wide bowl, top-down. |
| `dish-roasted-chickpeas` | roasted chickpeas | Crispy spiced roasted chickpeas in a small bowl, a few scattered around it, 45-degree angle. |
| `dish-hot-dog` | hot dog | *(Spare, not in the book; Apple Intelligence often writes it.)* A grilled hot dog in a bun with mustard and onions, 45-degree angle. |
| `dish-grain-bowl` | grain bowl, buddha bowl | *(Spare, not in the book; Apple Intelligence often writes it.)* A grain bowl with quinoa, roasted vegetables, chickpeas and tahini, top-down. |
