import SwiftUI
import UserNotifications
import PDFKit

// Models
struct Step: Codable, Identifiable {
    let id = UUID()
    let text: String
    let image: String?
}

struct Recipe: Identifiable, Codable {
    let id = UUID()
    let title: String
    let category: String
    let difficulty: String
    let time: String
    let calories: Int
    let image: String
    let ingredients: [String]
    let steps: [Step]
    var isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, category, difficulty, time, calories, image, ingredients, steps, isFavorite
    }
}

struct Note: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let tags: [String]
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, tags, date
    }
}

struct TimerModel: Identifiable {
    let id = UUID()
    let title: String
    let duration: TimeInterval
    var timeRemaining: TimeInterval
    var isRunning: Bool = false
}

struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let image: String
    let dateEarned: Date
}

// Colors
extension Color {
    static let yolkYellow = Color(hex: "#FFD93D")
    static let coralRed = Color(hex: "#FF6B6B")
    static let limeGreen = Color(hex: "#6CFF72")
    static let softBlue = Color(hex: "#AEE6FF")
    static let cozyWhite = Color(hex: "#F8F8F8")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// Main App
@main
struct EggCookProApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, .light)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            RecipesView(viewModel: viewModel)
                .tabItem {
                    Label("Recipes", systemImage: "frying.pan.fill")
                }
                .tag(1)
            
            TimersView(viewModel: viewModel)
                .tabItem {
                    Label("Timers", systemImage: "timer")
                }
                .tag(2)
            
            NotesView(viewModel: viewModel)
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(3)
            
            FavoritesView(viewModel: viewModel)
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
                .tag(4)
        }
        .accentColor(.yolkYellow)
        .font(.custom("Nunito", size: 16))
        .onAppear {
            viewModel.scheduleDailyRecipeNotification()
        }
    }
}

// ViewModel
class AppViewModel: ObservableObject {
    @Published var recipes: [Recipe] = [
        Recipe(
                    title: "Eggs Benedict",
                    category: "Breakfast",
                    difficulty: "Medium",
                    time: "20 min",
                    calories: 350,
                    image: "eggs_benedict",
                    ingredients: ["2 eggs", "1 English muffin", "2 slices Canadian bacon", "Hollandaise sauce", "Salt", "Pepper"],
                    steps: [
                        Step(text: "Poach eggs in simmering water with a splash of vinegar", image: "step_poach"),
                        Step(text: "Toast English muffin halves", image: "step_toast"),
                        Step(text: "Cook Canadian bacon until crispy", image: nil),
                        Step(text: "Assemble with muffin, bacon, egg, and hollandaise", image: "step_assemble")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Classic Omelette",
                    category: "Breakfast",
                    difficulty: "Easy",
                    time: "10 min",
                    calories: 200,
                    image: "omelette",
                    ingredients: ["3 eggs", "2 tbsp milk", "1/4 cup shredded cheddar", "Salt", "Pepper", "1 tbsp butter"],
                    steps: [
                        Step(text: "Whisk eggs with milk, salt, and pepper", image: nil),
                        Step(text: "Melt butter in a non-stick pan over medium heat", image: nil),
                        Step(text: "Pour egg mixture and cook until edges set", image: "step_omelette"),
                        Step(text: "Add cheese and fold omelette in half", image: nil)
                    ],
                    isFavorite: true
                ),
                Recipe(
                    title: "Scrambled Eggs with Chives",
                    category: "Breakfast",
                    difficulty: "Easy",
                    time: "8 min",
                    calories: 180,
                    image: "scrambled_eggs",
                    ingredients: ["3 eggs", "2 tbsp cream", "1 tbsp chopped chives", "Salt", "Pepper", "1 tbsp butter"],
                    steps: [
                        Step(text: "Whisk eggs with cream, salt, and pepper", image: nil),
                        Step(text: "Melt butter in a pan over low heat", image: nil),
                        Step(text: "Add eggs and stir gently until soft curds form", image: "step_scramble"),
                        Step(text: "Sprinkle with chives and serve", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg Fried Rice",
                    category: "Breakfast",
                    difficulty: "Medium",
                    time: "15 min",
                    calories: 250,
                    image: "egg_fried_rice",
                    ingredients: ["2 eggs", "1 cup cooked rice", "1/4 cup peas", "1/4 cup carrots", "2 tbsp soy sauce", "2 tbsp oil"],
                    steps: [
                        Step(text: "Scramble eggs and set aside", image: "step_scramble"),
                        Step(text: "Heat oil and stir-fry vegetables", image: nil),
                        Step(text: "Add rice and soy sauce, stir well", image: nil),
                        Step(text: "Mix in scrambled eggs and serve", image: "step_fried_rice")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg and Avocado Toast",
                    category: "Breakfast",
                    difficulty: "Easy",
                    time: "10 min",
                    calories: 300,
                    image: "avocado_toast",
                    ingredients: ["1 egg", "1 slice whole-grain bread", "1/2 avocado", "Lemon juice", "Salt", "Red pepper flakes"],
                    steps: [
                        Step(text: "Toast bread until golden", image: "step_toast"),
                        Step(text: "Mash avocado with lemon juice and salt", image: nil),
                        Step(text: "Fry egg sunny-side up", image: "step_fry"),
                        Step(text: "Spread avocado on toast, top with egg", image: "step_assemble")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg Custard Tart",
                    category: "Desserts",
                    difficulty: "Hard",
                    time: "1 hr",
                    calories: 400,
                    image: "custard_tart",
                    ingredients: ["4 eggs", "1 cup sugar", "2 cups milk", "1 tsp vanilla", "1 pie crust", "Nutmeg"],
                    steps: [
                        Step(text: "Preheat oven to 350°F", image: nil),
                        Step(text: "Whisk eggs, sugar, milk, and vanilla", image: nil),
                        Step(text: "Pour into pie crust, sprinkle with nutmeg", image: "step_pour"),
                        Step(text: "Bake for 45-50 minutes until set", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Meringue Cookies",
                    category: "Desserts",
                    difficulty: "Medium",
                    time: "2 hr",
                    calories: 100,
                    image: "meringue_cookies",
                    ingredients: ["3 egg whites", "3/4 cup sugar", "1/4 tsp cream of tartar", "1 tsp vanilla"],
                    steps: [
                        Step(text: "Preheat oven to 200°F", image: nil),
                        Step(text: "Beat egg whites with cream of tartar until foamy", image: nil),
                        Step(text: "Add sugar gradually, beat until stiff peaks form", image: "step_meringue"),
                        Step(text: "Pipe onto baking sheet, bake for 1.5 hours", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Lemon Soufflé",
                    category: "Desserts",
                    difficulty: "Hard",
                    time: "45 min",
                    calories: 320,
                    image: "lemon_souffle",
                    ingredients: ["4 eggs", "1/2 cup sugar", "1/4 cup lemon juice", "2 tbsp flour", "Butter", "Powdered sugar"],
                    steps: [
                        Step(text: "Preheat oven to 375°F, butter ramekins", image: nil),
                        Step(text: "Separate eggs, whisk yolks with sugar and lemon juice", image: nil),
                        Step(text: "Beat egg whites to stiff peaks, fold into yolk mixture", image: "step_fold"),
                        Step(text: "Bake for 15-20 minutes, dust with powdered sugar", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg Salad",
                    category: "Salads",
                    difficulty: "Easy",
                    time: "15 min",
                    calories: 220,
                    image: "egg_salad",
                    ingredients: ["4 eggs", "1/4 cup mayonnaise", "1 tbsp mustard", "1/4 cup celery", "Salt", "Pepper"],
                    steps: [
                        Step(text: "Boil eggs for 10 minutes, cool and peel", image: "step_boil"),
                        Step(text: "Chop eggs and mix with mayonnaise, mustard, and celery", image: nil),
                        Step(text: "Season with salt and pepper", image: nil),
                        Step(text: "Serve on lettuce or bread", image: "step_assemble")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Cobb Salad with Eggs",
                    category: "Salads",
                    difficulty: "Medium",
                    time: "25 min",
                    calories: 400,
                    image: "cobb_salad",
                    ingredients: ["2 eggs", "2 cups lettuce", "1/2 avocado", "1/4 cup bacon", "1/4 cup blue cheese", "Vinaigrette"],
                    steps: [
                        Step(text: "Boil eggs for 10 minutes, cool and peel", image: "step_boil"),
                        Step(text: "Chop lettuce, avocado, and bacon", image: nil),
                        Step(text: "Slice eggs and arrange with ingredients on plate", image: "step_assemble"),
                        Step(text: "Drizzle with vinaigrette", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Spinach and Egg Salad",
                    category: "Salads",
                    difficulty: "Easy",
                    time: "15 min",
                    calories: 200,
                    image: "spinach_egg_salad",
                    ingredients: ["2 eggs", "2 cups spinach", "1/4 cup cherry tomatoes", "1 tbsp olive oil", "1 tbsp balsamic vinegar"],
                    steps: [
                        Step(text: "Boil eggs for 8 minutes, cool and peel", image: "step_boil"),
                        Step(text: "Toss spinach and halved tomatoes with oil and vinegar", image: nil),
                        Step(text: "Slice eggs and add to salad", image: "step_assemble"),
                        Step(text: "Serve immediately", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg Drop Soup",
                    category: "Soups",
                    difficulty: "Easy",
                    time: "15 min",
                    calories: 150,
                    image: "egg_drop_soup",
                    ingredients: ["2 eggs", "4 cups chicken broth", "1 tbsp cornstarch", "1 tsp soy sauce", "1/4 cup green onions"],
                    steps: [
                        Step(text: "Heat broth and soy sauce, mix cornstarch with water", image: nil),
                        Step(text: "Whisk eggs and drizzle into simmering broth", image: "step_egg_drop"),
                        Step(text: "Stir in cornstarch slurry to thicken", image: nil),
                        Step(text: "Garnish with green onions", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Stracciatella Soup",
                    category: "Soups",
                    difficulty: "Medium",
                    time: "20 min",
                    calories: 180,
                    image: "stracciatella_soup",
                    ingredients: ["2 eggs", "4 cups chicken broth", "1/4 cup Parmesan", "1 cup spinach", "1 tbsp parsley"],
                    steps: [
                        Step(text: "Heat broth and add chopped spinach", image: nil),
                        Step(text: "Whisk eggs with Parmesan", image: nil),
                        Step(text: "Drizzle egg mixture into simmering broth, stirring", image: "step_egg_drop"),
                        Step(text: "Garnish with parsley", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Chinese Egg Flower Soup",
                    category: "Soups",
                    difficulty: "Easy",
                    time: "15 min",
                    calories: 160,
                    image: "egg_flower_soup",
                    ingredients: ["2 eggs", "4 cups chicken broth", "1/2 cup corn", "1 tsp sesame oil", "1 tbsp soy sauce"],
                    steps: [
                        Step(text: "Heat broth with soy sauce and sesame oil", image: nil),
                        Step(text: "Add corn and simmer", image: nil),
                        Step(text: "Whisk eggs and drizzle into broth", image: "step_egg_drop"),
                        Step(text: "Stir gently and serve", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Quiche Lorraine",
                    category: "Baking",
                    difficulty: "Hard",
                    time: "1 hr",
                    calories: 450,
                    image: "quiche_lorraine",
                    ingredients: ["4 eggs", "1 pie crust", "1 cup cream", "1/2 cup bacon", "1/2 cup Gruyère cheese", "Salt"],
                    steps: [
                        Step(text: "Preheat oven to 375°F, prepare pie crust", image: nil),
                        Step(text: "Cook bacon until crispy, drain", image: nil),
                        Step(text: "Whisk eggs with cream, salt, and cheese", image: nil),
                        Step(text: "Pour into crust, bake for 35-40 minutes", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg and Cheese Muffins",
                    category: "Baking",
                    difficulty: "Medium",
                    time: "30 min",
                    calories: 250,
                    image: "egg_muffins",
                    ingredients: ["6 eggs", "1/2 cup milk", "1 cup shredded cheddar", "1/4 cup spinach", "Salt", "Pepper"],
                    steps: [
                        Step(text: "Preheat oven to 350°F, grease muffin tin", image: nil),
                        Step(text: "Whisk eggs with milk, salt, and pepper", image: nil),
                        Step(text: "Mix in cheese and spinach", image: nil),
                        Step(text: "Pour into muffin tin, bake for 20-25 minutes", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Deviled Eggs",
                    category: "Salads",
                    difficulty: "Easy",
                    time: "20 min",
                    calories: 200,
                    image: "deviled_eggs",
                    ingredients: ["6 eggs", "1/4 cup mayonnaise", "1 tsp mustard", "Paprika", "Salt", "Pepper"],
                    steps: [
                        Step(text: "Boil eggs for 10 minutes, cool and peel", image: "step_boil"),
                        Step(text: "Halve eggs, remove yolks", image: nil),
                        Step(text: "Mix yolks with mayonnaise, mustard, salt, and pepper", image: nil),
                        Step(text: "Pipe filling into egg whites, sprinkle with paprika", image: "step_assemble")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Egg and Potato Bake",
                    category: "Baking",
                    difficulty: "Medium",
                    time: "45 min",
                    calories: 350,
                    image: "egg_potato_bake",
                    ingredients: ["4 eggs", "2 cups diced potatoes", "1/2 cup cheese", "1/4 cup milk", "Salt", "Pepper"],
                    steps: [
                        Step(text: "Preheat oven to 375°F", image: nil),
                        Step(text: "Cook potatoes until tender", image: nil),
                        Step(text: "Whisk eggs with milk, salt, and pepper", image: nil),
                        Step(text: "Layer potatoes and cheese in dish, pour eggs over, bake 30 minutes", image: "step_bake")
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "French Toast",
                    category: "Breakfast",
                    difficulty: "Easy",
                    time: "15 min",
                    calories: 300,
                    image: "french_toast",
                    ingredients: ["2 eggs", "4 slices bread", "1/2 cup milk", "1 tsp cinnamon", "1 tbsp butter", "Maple syrup"],
                    steps: [
                        Step(text: "Whisk eggs with milk and cinnamon", image: nil),
                        Step(text: "Dip bread in egg mixture", image: "step_dip"),
                        Step(text: "Cook in buttered pan until golden", image: "step_fry"),
                        Step(text: "Serve with maple syrup", image: nil)
                    ],
                    isFavorite: false
                ),
                Recipe(
                    title: "Pavlova",
                    category: "Desserts",
                    difficulty: "Hard",
                    time: "2 hr",
                    calories: 250,
                    image: "pavlova",
                    ingredients: ["4 egg whites", "1 cup sugar", "1 tsp vinegar", "1 tsp cornstarch", "1 cup whipped cream", "Fruit"],
                    steps: [
                        Step(text: "Preheat oven to 250°F", image: nil),
                        Step(text: "Beat egg whites to soft peaks, add sugar gradually", image: "step_meringue"),
                        Step(text: "Fold in vinegar and cornstarch, shape on baking sheet", image: nil),
                        Step(text: "Bake for 1.5 hours, top with cream and fruit", image: "step_assemble")
                    ],
                    isFavorite: false
                )
    ]
    @Published var notes: [Note] = []
    @Published var timers: [TimerModel] = [
        TimerModel(title: "Soft-boiled Egg", duration: 360, timeRemaining: 360),
        TimerModel(title: "Poached Egg", duration: 240, timeRemaining: 240)
    ]
    @Published var badges: [Badge] = []
    @Published var viewedRecipesCount: Int = 0
    
    func toggleFavorite(recipeId: UUID) {
        if let index = recipes.firstIndex(where: { $0.id == recipeId }) {
            recipes[index].isFavorite.toggle()
            if recipes[index].isFavorite && viewedRecipesCount >= 5 && !badges.contains(where: { $0.title == "Egg Champion" }) {
                badges.append(Badge(title: "Egg Champion", description: "Cooked 5 recipes!", image: "egg_champion", dateEarned: Date()))
                scheduleBadgeNotification(title: "Egg Champion")
            }
        }
    }
    
    func addNote(title: String, content: String, tags: [String]) {
        notes.append(Note(title: title, content: content, tags: tags, date: Date()))
    }
    
    func startTimer(timerId: UUID) {
        if let index = timers.firstIndex(where: { $0.id == timerId }) {
            timers[index].isRunning = true
            timers[index].timeRemaining = timers[index].duration
            scheduleTimerNotification(timer: timers[index])
        }
    }
    
    func stopTimer(timerId: UUID) {
        if let index = timers.firstIndex(where: { $0.id == timerId }) {
            timers[index].isRunning = false
        }
    }
    
    func scheduleTimerNotification(timer: TimerModel) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = "Your \(timer.title) timer is done!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timer.duration, repeats: false)
        let request = UNNotificationRequest(identifier: timer.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDailyRecipeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Recipe of the Day"
        content.body = "Check out today's recipe: \(recipes.first?.title ?? "Eggs Benedict")!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyRecipe", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBadgeNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Badge Earned!"
        content.body = "Congratulations! You've earned the '\(title)' badge!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func searchRecipes(byIngredients: [String]) -> [Recipe] {
        recipes.filter { recipe in
            byIngredients.allSatisfy { ingredient in
                recipe.ingredients.contains { $0.lowercased().contains(ingredient.lowercased()) }
            }
        }
    }
    
    func exportRecipeToPDF(recipe: Recipe) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Egg Cook Pro",
            kCGPDFContextAuthor: "User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "Poppins-Bold", size: 24)!]
            let bodyAttributes = [NSAttributedString.Key.font: UIFont(name: "Nunito-Regular", size: 16)!]
            
            let title = NSAttributedString(string: recipe.title, attributes: titleAttributes)
            title.draw(at: CGPoint(x: 20, y: 20))
            
            var yOffset: CGFloat = 60
            let info = "\(recipe.time) • \(recipe.calories) kcal • \(recipe.difficulty)"
            NSAttributedString(string: info, attributes: bodyAttributes).draw(at: CGPoint(x: 20, y: yOffset))
            
            yOffset += 40
            NSAttributedString(string: "Ingredients", attributes: titleAttributes).draw(at: CGPoint(x: 20, y: yOffset))
            yOffset += 20
            for ingredient in recipe.ingredients {
                NSAttributedString(string: "• \(ingredient)", attributes: bodyAttributes).draw(at: CGPoint(x: 20, y: yOffset))
                yOffset += 20
            }
            
            yOffset += 20
            NSAttributedString(string: "Steps", attributes: titleAttributes).draw(at: CGPoint(x: 20, y: yOffset))
            yOffset += 20
            for (index, step) in recipe.steps.enumerated() {
                NSAttributedString(string: "\(index + 1). \(step.text)", attributes: bodyAttributes).draw(at: CGPoint(x: 20, y: yOffset))
                yOffset += 20
            }
        }
        return data
    }
}

// Home View
struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showProfile: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recipe of the Day
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(LinearGradient(gradient: Gradient(colors: [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 220)
                        Image(viewModel.recipes.first?.image ?? "placeholder")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.cozyWhite, lineWidth: 2)
                                    .shadow(radius: 5)
                            )
                        VStack {
                            Text("Recipe of the Day")
                                .font(.custom("Poppins-Bold", size: 20))
                                .foregroundColor(.white)
                            Text(viewModel.recipes.first?.title ?? "Eggs Benedict")
                                .font(.custom("Poppins-Bold", size: 24))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .scaleEffect(showProfile ? 0.95 : 1)
                    .animation(.spring(), value: showProfile)
                    .accessibilityLabel("Recipe of the Day: \(viewModel.recipes.first?.title ?? "Eggs Benedict")")
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(["Breakfast", "Desserts", "Salads", "Soups", "Baking"], id: \.self) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tip of the Day
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tip of the Day")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.black)
                        Text("Swirl the water gently before adding eggs for the perfect poach!")
                            .font(.custom("Nunito-Regular", size: 16))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.softBlue.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.softBlue, lineWidth: 1))
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tip of the Day: Swirl the water gently before adding eggs for the perfect poach")
                    
                    // Stats
                    HStack {
                        StatCard(title: "Recipes Viewed", value: "\(viewModel.viewedRecipesCount)")
                        StatCard(title: "Badges Earned", value: "\(viewModel.badges.count)")
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Egg Cook Pro")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.yolkYellow)
                            .font(.title2)
                    }
                    .accessibilityLabel("Open Profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(viewModel: viewModel)
            }
            .background(Color.cozyWhite)
        }
        .onAppear {
            viewModel.viewedRecipesCount = viewModel.recipes.count
        }
    }
}

struct CategoryCard: View {
    let category: String
    @State private var isTapped = false
    
    var body: some View {
        VStack {
            Image(category.lowercased())
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.yolkYellow, lineWidth: 2))
                .shadow(radius: isTapped ? 8 : 4)
            Text(category)
                .font(.custom("Nunito-Bold", size: 14))
                .foregroundColor(.black)
        }
        .scaleEffect(isTapped ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
        .onTapGesture {
            isTapped = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
        .accessibilityLabel("Category: \(category)")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(.gray)
            Text(value)
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cozyWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// Recipes View
struct RecipesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedCategory: String? = nil
    @State private var searchText: String = ""
    @State private var ingredientSearch: [String] = []
    @State private var showIngredientSearch: Bool = false
    
    var filteredRecipes: [Recipe] {
        var result = viewModel.recipes
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
        if !ingredientSearch.isEmpty {
            result = viewModel.searchRecipes(byIngredients: ingredientSearch)
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["All", "Breakfast", "Desserts", "Salads", "Soups", "Baking"], id: \.self) { category in
                            Button(action: {
                                selectedCategory = category == "All" ? nil : category
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Text(category)
                                    .font(.custom("Nunito-Bold", size: 16))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == category || (category == "All" && selectedCategory == nil) ? Color.yolkYellow : Color.cozyWhite)
                                    .foregroundColor(selectedCategory == category || (category == "All" && selectedCategory == nil) ? .white : .black)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.yolkYellow, lineWidth: 1))
                                    .shadow(radius: 2)
                            }
                            .accessibilityLabel("Filter by \(category)")
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Search Bar
                HStack {
                    TextField("Search recipes...", text: $searchText)
                        .padding()
                        .background(Color.cozyWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yolkYellow, lineWidth: 1))
                        .accessibilityLabel("Search recipes")
                    Button(action: { showIngredientSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.yolkYellow)
                            .padding()
                            .background(Color.cozyWhite)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel("Search by ingredients")
                }
                .padding(.horizontal)
                
                // Recipes List
                if filteredRecipes.isEmpty {
                    VStack {
                        Image(systemName: "egg.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.yolkYellow)
                        Text("No recipes found")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No recipes found")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 15)], spacing: 15) {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(viewModel: viewModel, recipe: recipe)) {
                                    RecipeCard(recipe: recipe)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recipes")
            .sheet(isPresented: $showIngredientSearch) {
                IngredientSearchView(ingredients: $ingredientSearch)
            }
            .background(Color.cozyWhite)
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    @State private var isTapped = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Image(recipe.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                if recipe.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yolkYellow)
                        .padding(8)
                        .background(Color.cozyWhite)
                        .clipShape(Circle())
                        .offset(x: 60, y: -50)
                }
            }
            Text(recipe.title)
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundColor(.black)
                .lineLimit(1)
            Text("\(recipe.time) • \(recipe.difficulty)")
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.cozyWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
        .scaleEffect(isTapped ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
        .onTapGesture {
            isTapped = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.title), \(recipe.time), \(recipe.difficulty)\(recipe.isFavorite ? ", favorited" : "")")
    }
}

struct IngredientSearchView: View {
    @Binding var ingredients: [String]
    @State private var newIngredient: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Add ingredient (e.g., eggs, milk)", text: $newIngredient)
                    .padding()
                    .background(Color.cozyWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yolkYellow, lineWidth: 1))
                    .padding(.horizontal)
                    .accessibilityLabel("Add ingredient")
                
                Button(action: {
                    if !newIngredient.isEmpty {
                        ingredients.append(newIngredient)
                        newIngredient = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }) {
                    Text("Add Ingredient")
                        .font(.custom("Nunito-Bold", size: 16))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 3)
                }
                .padding(.horizontal)
                .accessibilityLabel("Add ingredient to search")
                
                List {
                    ForEach(ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.custom("Nunito-Regular", size: 16))
                    }
                    .onDelete { indices in
                        ingredients.remove(atOffsets: indices)
                    }
                }
                .accessibilityLabel("List of ingredients")
            }
            .navigationTitle("Search by Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Nunito-Bold", size: 16))
                        .foregroundColor(.yolkYellow)
                        .accessibilityLabel("Done")
                }
            }
            .background(Color.cozyWhite)
        }
    }
}

struct RecipeDetailView: View {
    @ObservedObject var viewModel: AppViewModel
    let recipe: Recipe
    @State private var checkedIngredients: [Bool]
    @State private var showTimer: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var pdfData: Data?
    
    init(viewModel: AppViewModel, recipe: Recipe) {
        self.viewModel = viewModel
        self.recipe = recipe
        self._checkedIngredients = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(recipe.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yolkYellow, lineWidth: 2)
                            .shadow(radius: 5)
                    )
                    .accessibilityLabel("Image of \(recipe.title)")
                
                Text(recipe.title)
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.black)
                
                HStack {
                    Text("\(recipe.time)")
                    Spacer()
                    Text("\(recipe.calories) kcal")
                    Spacer()
                    Text(recipe.difficulty)
                }
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.gray)
                
                // Ingredients
                Text("Ingredients")
                    .font(.custom("Poppins-Bold", size: 20))
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: checkedIngredients[index] ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.yolkYellow)
                            .onTapGesture {
                                checkedIngredients[index].toggle()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        Text(recipe.ingredients[index])
                            .font(.custom("Nunito-Regular", size: 16))
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(recipe.ingredients[index])\(checkedIngredients[index] ? ", checked" : "")")
                    .accessibilityHint("Tap to toggle ingredient")
                }
                
                // Steps
                Text("Steps")
                    .font(.custom("Poppins-Bold", size: 20))
                ForEach(recipe.steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(step.id.uuidString.prefix(1))")
                            .font(.custom("Nunito-Bold", size: 16))
                            .foregroundColor(.yolkYellow)
                        VStack(alignment: .leading) {
                            Text(step.text)
                                .font(.custom("Nunito-Regular", size: 16))
                            if let stepImage = step.image {
                                Image(stepImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel("Step image")
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step: \(step.text)")
                }
                
                // Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        showTimer = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Text("Start Timer")
                            .font(.custom("Nunito-Bold", size: 16))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Start timer for recipe")
                    
                    Button(action: {
                        viewModel.toggleFavorite(recipeId: recipe.id)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.yolkYellow)
                            .padding()
                            .background(Color.cozyWhite)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
                    
                    Button(action: {
                        pdfData = viewModel.exportRecipeToPDF(recipe: recipe)
                        showShareSheet = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.yolkYellow)
                            .padding()
                            .background(Color.cozyWhite)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .accessibilityLabel("Share recipe")
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .background(Color.cozyWhite)
        .sheet(isPresented: $showTimer) {
            TimerView(viewModel: viewModel, timer: Binding(
                get: { TimerModel(title: recipe.title, duration: 300, timeRemaining: 300) },
                set: { _ in }
            ))
        }
        .sheet(isPresented: $showShareSheet, content: {
            if let pdfData = pdfData {
                ActivityView(activityItems: [pdfData], applicationActivities: nil)
            }
        })
        .onAppear {
            viewModel.viewedRecipesCount += 1
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Timer View
struct TimerView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var timer: TimerModel
    @State private var eggCrackProgress: Double = 0
    @State private var timerInstance: Timer?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius = size.width / 2
                        context.stroke(
                            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.limeGreen),
                            lineWidth: 4
                        )
                        context.stroke(
                            Path { path in
                                path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * eggCrackProgress), clockwise: false)
                            },
                            with: .color(.yolkYellow),
                            lineWidth: 4
                        )
                        // Simulate egg cracking
                        if eggCrackProgress > 0.7 {
                            context.stroke(
                                Path { path in
                                    path.move(to: CGPoint(x: center.x - 20, y: center.y))
                                    path.addLine(to: CGPoint(x: center.x + 20, y: center.y))
                                },
                                with: .color(.black),
                                lineWidth: 2
                            )
                        }
                    }
                    .frame(width: 120, height: 120)
                    Image("egg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(timer.isRunning ? 1.1 : 1)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timer.isRunning)
                        .rotationEffect(.degrees(eggCrackProgress * 10))
                        .accessibilityLabel("Timer progress")
                }
                Text(timer.title)
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.black)
                Text("\(Int(timer.timeRemaining)) sec")
                    .font(.custom("Nunito-Regular", size: 18))
                    .foregroundColor(.gray)
                Button(action: {
                    if timer.isRunning {
                        viewModel.stopTimer(timerId: timer.id)
                        timerInstance?.invalidate()
                        timer.isRunning = false
                        eggCrackProgress = 0
                    } else {
                        viewModel.startTimer(timerId: timer.id)
                        timer.isRunning = true
                        timerInstance = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            if timer.timeRemaining > 0 {
                                timer.timeRemaining -= 1
                                eggCrackProgress = 1 - (timer.timeRemaining / timer.duration)
                            } else {
                                timerInstance?.invalidate()
                                timer.isRunning = false
                                eggCrackProgress = 0
                                timer.timeRemaining = timer.duration
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            }
                        }
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text(timer.isRunning ? "Stop" : "Start")
                        .font(.custom("Nunito-Bold", size: 16))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: timer.isRunning ? [.coralRed, .coralRed.opacity(0.8)] : [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 3)
                }
                .accessibilityLabel(timer.isRunning ? "Stop timer" : "Start timer")
            }
            .padding()
            .background(Color.cozyWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Nunito-Bold", size: 16))
                        .foregroundColor(.yolkYellow)
                        .accessibilityLabel("Close timer")
                }
            }
            .onDisappear {
                timerInstance?.invalidate()
            }
        }
    }
}

// Timers View
struct TimersView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.timers.isEmpty {
                    VStack {
                        Image(systemName: "timer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.yolkYellow)
                        Text("No timers set")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No timers set")
                } else {
                    VStack(spacing: 20) {
                        ForEach($viewModel.timers) { $timer in
                            TimerCard(viewModel: viewModel, timer: $timer)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Timers")
            .background(Color.cozyWhite)
        }
    }
}

struct TimerCard: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var timer: TimerModel
    @State private var eggCrackProgress: Double = 0
    @State private var timerInstance: Timer?
    
    var body: some View {
        VStack {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = size.width / 2
                    context.stroke(
                        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(.limeGreen),
                        lineWidth: 4
                    )
                    context.stroke(
                        Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * eggCrackProgress), clockwise: false)
                        },
                        with: .color(.yolkYellow),
                        lineWidth: 4
                    )
                    // Simulate egg cracking
                    if eggCrackProgress > 0.7 {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: center.x - 20, y: center.y))
                                path.addLine(to: CGPoint(x: center.x + 20, y: center.y))
                            },
                            with: .color(.black),
                            lineWidth: 2
                        )
                    }
                }
                .frame(width: 120, height: 120)
                Image("egg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .scaleEffect(timer.isRunning ? 1.1 : 1)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timer.isRunning)
                    .rotationEffect(.degrees(eggCrackProgress * 10))
                    .accessibilityLabel("Timer progress")
            }
            Text(timer.title)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.black)
            Text("\(Int(timer.timeRemaining)) sec")
                .font(.custom("Nunito-Regular", size: 16))
                .foregroundColor(.gray)
            Button(action: {
                if timer.isRunning {
                    viewModel.stopTimer(timerId: timer.id)
                    timerInstance?.invalidate()
                    timer.isRunning = false
                    eggCrackProgress = 0
                } else {
                    viewModel.startTimer(timerId: timer.id)
                    timer.isRunning = true
                    timerInstance = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        if timer.timeRemaining > 0 {
                            timer.timeRemaining -= 1
                            eggCrackProgress = 1 - (timer.timeRemaining / timer.duration)
                        } else {
                            timerInstance?.invalidate()
                            timer.isRunning = false
                            eggCrackProgress = 0
                            timer.timeRemaining = timer.duration
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        }
                    }
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Text(timer.isRunning ? "Stop" : "Start")
                    .font(.custom("Nunito-Bold", size: 16))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: timer.isRunning ? [.coralRed, .coralRed.opacity(0.8)] : [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 3)
            }
            .accessibilityLabel(timer.isRunning ? "Stop timer" : "Start timer")
        }
        .padding()
        .background(Color.cozyWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
        .onDisappear {
            timerInstance?.invalidate()
        }
    }
}

// Notes View
struct NotesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var newNoteTitle: String = ""
    @State private var newNoteContent: String = ""
    @State private var newNoteTags: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Add Note
                VStack(spacing: 10) {
                    TextField("Note Title", text: $newNoteTitle)
                        .padding()
                        .background(Color.cozyWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yolkYellow, lineWidth: 1))
                        .accessibilityLabel("Note title")
                    TextEditor(text: $newNoteContent)
                        .frame(height: 100)
                        .padding()
                        .background(Color.cozyWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yolkYellow, lineWidth: 1))
                        .accessibilityLabel("Note content")
                    TextField("Tags (comma-separated)", text: $newNoteTags)
                        .padding()
                        .background(Color.cozyWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yolkYellow, lineWidth: 1))
                        .accessibilityLabel("Note tags")
                    Button(action: {
                        if !newNoteTitle.isEmpty && !newNoteContent.isEmpty {
                            let tags = newNoteTags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                            viewModel.addNote(title: newNoteTitle, content: newNoteContent, tags: tags)
                            newNoteTitle = ""
                            newNoteContent = ""
                            newNoteTags = ""
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Text("Add Note")
                            .font(.custom("Nunito-Bold", size: 16))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [.yolkYellow, .softBlue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Add note")
                }
                .padding()
                
                // Notes List
                if viewModel.notes.isEmpty {
                    VStack {
                        Image(systemName: "note.text")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.yolkYellow)
                        Text("No notes yet")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No notes yet")
                } else {
                    ScrollView {
                        ForEach(viewModel.notes) { note in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(note.title)
                                    .font(.custom("Poppins-Bold", size: 16))
                                    .foregroundColor(.black)
                                Text(note.content)
                                    .font(.custom("Nunito-Regular", size: 14))
                                    .foregroundColor(.gray)
                                HStack {
                                    ForEach(note.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.custom("Nunito-Regular", size: 12))
                                            .padding(5)
                                            .background(Color.softBlue.opacity(0.3))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(note.date, style: .date)
                                    .font(.custom("Nunito-Regular", size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.cozyWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Note: \(note.title), \(note.content), tags: \(note.tags.joined(separator: ", ")), created on \(note.date, style: .date)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("My Notes")
            .background(Color.cozyWhite)
        }
    }
}

// Favorites View
struct FavoritesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var sortOption: String = "Date"
    
    var sortedRecipes: [Recipe] {
        let favorites = viewModel.recipes.filter { $0.isFavorite }
        switch sortOption {
        case "Name":
            return favorites.sorted { $0.title < $1.title }
        case "Difficulty":
            return favorites.sorted { $0.difficulty < $1.difficulty }
        default:
            return favorites
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Sort by", selection: $sortOption) {
                    Text("Date").tag("Date")
                    Text("Name").tag("Name")
                    Text("Difficulty").tag("Difficulty")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .accessibilityLabel("Sort favorites")
                
                if sortedRecipes.isEmpty {
                    VStack {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.yolkYellow)
                        Text("No favorite recipes yet")
                            .font(.custom("Poppins-Bold", size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No favorite recipes")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 15)], spacing: 15) {
                            ForEach(sortedRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(viewModel: viewModel, recipe: recipe)) {
                                    RecipeCard(recipe: recipe)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .background(Color.cozyWhite)
        }
    }
}

// Profile View
struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Stats
                    HStack {
                        StatCard(title: "Recipes Viewed", value: "\(viewModel.viewedRecipesCount)")
                        StatCard(title: "Recipes Favorited", value: "\(viewModel.recipes.filter { $0.isFavorite }.count)")
                    }
                    .padding(.horizontal)
                    
                    // Badges
                    Text("Badges")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    if viewModel.badges.isEmpty {
                        Text("No badges earned yet")
                            .font(.custom("Nunito-Regular", size: 16))
                            .foregroundColor(.gray)
                            .accessibilityLabel("No badges earned")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 15)], spacing: 15) {
                            ForEach(viewModel.badges) { badge in
                                VStack {
                                    Image(badge.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.yolkYellow, lineWidth: 2))
                                    Text(badge.title)
                                        .font(.custom("Poppins-Bold", size: 14))
                                        .foregroundColor(.black)
                                    Text(badge.description)
                                        .font(.custom("Nunito-Regular", size: 12))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(Color.cozyWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 2, y: 2)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Badge: \(badge.title), \(badge.description)")
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Nunito-Bold", size: 16))
                        .foregroundColor(.yolkYellow)
                        .accessibilityLabel("Close profile")
                }
            }
            .background(Color.cozyWhite)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
