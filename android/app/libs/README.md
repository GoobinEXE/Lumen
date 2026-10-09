# Samsung Health Data SDK

Coloque aqui o AAR oficial (`samsung-health-data-api-*.aar`) baixado de
[Samsung Developer — Health Data SDK](https://developer.samsung.com/health/data/overview.html).

Depois, em `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("com.google.code.gson:gson:2.13.2")
}
```

E ative `kotlin-parcelize` nos plugins do módulo.

Sem o AAR o app compila normalmente: detecta o Samsung Health instalado e usa
Health Connect como fallback de dados. Distribuição pública do Data SDK exige
partnership Samsung (package + SHA-256).
