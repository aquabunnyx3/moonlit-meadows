import SwiftUI

/// The pantry: one tab, two shelves — the Dishes you've cooked or baked, and
/// the Recipes that make them. (The full inventory lives on the deck.)
struct PantryTab: View {
    let meadow: Meadow
    @State private var section = DishSection.dishes

    enum DishSection: String, CaseIterable {
        case dishes = "Dishes"
        case recipes = "Recipes"
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Pantry", selection: $section) {
                ForEach(DishSection.allCases, id: \.self) { section in
                    Text(section.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

            switch section {
            case .dishes: dishes
            case .recipes: recipes
            }
        }
    }

    // MARK: Dishes

    @ViewBuilder
    private var dishes: some View {
        let items = Recipe.all.map(\.id).filter { meadow.count(of: $0) > 0 }
        if meadow.coziness > 0 {
            Text("Coziness bonus: everything sells for +\(meadow.coziness)%")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Palette.mint, in: .capsule)
        }
        if items.isEmpty {
            ContentUnavailableView {
                Label("No dishes yet", systemImage: "fork.knife")
            } description: {
                Text("Bake something from Recipes and it will wait for you here.")
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items, id: \.self) { id in
                        basketRow(id)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func basketRow(_ id: String) -> some View {
        let count = meadow.count(of: id)
        let price = meadow.salePrice(of: id)
        let lureCount = Breed.all.filter { $0.lure.contains(id) }.count

        return CozyCard {
            HStack(spacing: 10) {
                ItemIcon(itemID: id, size: 28)
                    .frame(width: 46, height: 46)
                    .background(Palette.blush, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ItemInfo.name(id)) ×\(count)")
                        .font(.headline)
                        .contentTransition(.numericText())
                        .popOnIncrease(count, scale: 1.15)
                    coinText(lureCount > 0 ? "🪙 \(price) each · lures \(lureCount) breed\(lureCount == 1 ? "" : "s")" : "🪙 \(price) each")
                        .font(.caption)
                        .opacity(0.7)
                }
                Spacer(minLength: 6)
                PriceButton(label: "Sell 1", isEnabled: true, color: Palette.lilac) {
                    meadow.sell(id, count: 1)
                }
                PriceButton(label: "All · 🪙 \((price * count).cozy)", isEnabled: true) {
                    meadow.sell(id, count: count)
                }
            }
        }
    }

    // MARK: Recipes

    private var recipes: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Recipe.all) { recipe in
                    recipeRow(recipe)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func recipeRow(_ recipe: Recipe) -> some View {
        let isUnlocked = meadow.isUnlocked(recipe)
        let teacher = recipe.taughtBy.flatMap(Person.find)
        let lockedText: String
        if let teacher, !meadow.learnedRecipes.contains(recipe.id) {
            lockedText = "\(teacher.name) will teach you this in their story"
        } else {
            lockedText = "Unlocks at Lv \(recipe.unlockLevel)"
        }

        return CozyCard {
            HStack(spacing: 10) {
                Group {
                    if isUnlocked {
                        ItemIcon(itemID: recipe.id, size: 28)
                    } else {
                        Image(systemName: "lock.fill").foregroundStyle(Palette.ink.opacity(0.5))
                    }
                }
                .frame(width: 46, height: 46)
                .background(Palette.butter.opacity(0.7), in: .circle)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(isUnlocked || teacher != nil ? recipe.name : "Secret Recipe")
                            .font(.headline)
                        if let teacher {
                            CozyTag(text: "\(teacher.name)'s recipe", color: Palette.petal)
                        }
                    }
                    if isUnlocked {
                        HStack(spacing: 6) {
                            ForEach(recipe.ingredients, id: \.itemID) { ingredient in
                                let have = meadow.count(of: ingredient.itemID)
                                HStack(spacing: 2) {
                                    ItemIcon(itemID: ingredient.itemID, size: 13)
                                    Text("\(have)/\(ingredient.count)")
                                }
                                .font(.caption.bold())
                                .monospacedDigit()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(have >= ingredient.count ? Palette.mint : Palette.blush, in: .capsule)
                            }
                            coinText("→ 🪙 \(meadow.salePrice(of: recipe.id))")
                                .font(.caption)
                                .opacity(0.7)
                        }
                    } else {
                        Text(lockedText)
                            .font(.caption)
                            .opacity(0.7)
                    }
                }
                Spacer(minLength: 6)
                if isUnlocked {
                    PriceButton(label: "Bake", isEnabled: meadow.canCraft(recipe)) {
                        meadow.craft(recipe)
                    }
                }
            }
        }
        .opacity(isUnlocked ? 1 : 0.6)
    }
}
