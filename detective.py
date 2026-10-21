import os
import re

PROJECT_DIR = r"C:\AScobrar\lib"

print("=" * 70)
print("🔎 SCRIPT DETECTIVE: AUDITORÍA DE FLUJO DE PAGOS (AScobrar)")
print("=" * 70)

checks = {
    "collector_write": {
        "title": "1. ¿Dónde y cómo escribe los pagos el Cobrador?",
        "patterns": [
            r"registerPayment",
            r"payments\.put",
            r"PaymentRepository",
            r"addPayment"
        ],
        "findings": []
    },
    "data_service_payment": {
        "title": "2. ¿Cómo almacena los pagos DataService / Repositorio?",
        "patterns": [
            r"static.*registerPayment",
            r"payments\.put\(",
            r"allPayments"
        ],
        "findings": []
    },
    "admin_read_dashboard": {
        "title": "3. ¿Cómo lee y filtra los pagos el Administrador en su Dashboard?",
        "patterns": [
            r"DataService\.allPayments",
            r"paymentsStreamProvider",
            r"totalCollected"
        ],
        "findings": []
    },
    "admin_read_reports": {
        "title": "4. ¿Cómo filtra los pagos DailyCollectionReportScreen?",
        "patterns": [
            r"payments",
            r"createdAt",
            r"DateTime",
            r"selectedDate"
        ],
        "findings": []
    },
    "stream_providers": {
        "title": "5. ¿Existen StreamProviders reactivos para pagos?",
        "patterns": [
            r"paymentsStreamProvider",
            r"paymentsProvider",
            r"payments\.watch"
        ],
        "findings": []
    }
}

for root, _, files in os.walk(PROJECT_DIR):
    for f in files:
        if not f.endswith(".dart"):
            continue
        filepath = os.path.join(root, f)
        rel_path = os.path.relpath(filepath, PROJECT_DIR)
        
        try:
            with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                lines = fp.readlines()
        except Exception:
            continue

        for i, line in enumerate(lines, 1):
            line_str = line.strip()
            if not line_str or line_str.startswith("//"):
                continue

            # 1. Cobrador
            if "collector" in rel_path.lower():
                for pat in checks["collector_write"]["patterns"]:
                    if re.search(pat, line_str, re.IGNORECASE):
                        checks["collector_write"]["findings"].append((rel_path, i, line_str))
                        break

            # 2. DataService
            if "data_service" in rel_path.lower() or "payment_repo" in rel_path.lower():
                for pat in checks["data_service_payment"]["patterns"]:
                    if re.search(pat, line_str, re.IGNORECASE):
                        checks["data_service_payment"]["findings"].append((rel_path, i, line_str))
                        break

            # 3. Owner Dashboard
            if "owner_dashboard" in rel_path.lower():
                for pat in checks["admin_read_dashboard"]["patterns"]:
                    if re.search(pat, line_str, re.IGNORECASE):
                        checks["admin_read_dashboard"]["findings"].append((rel_path, i, line_str))
                        break

            # 4. Reporte Diario
            if "daily_collection" in rel_path.lower() or "report" in rel_path.lower():
                for pat in checks["admin_read_reports"]["patterns"]:
                    if re.search(pat, line_str, re.IGNORECASE):
                        checks["admin_read_reports"]["findings"].append((rel_path, i, line_str))
                        break

            # 5. Providers
            if "provider" in rel_path.lower():
                for pat in checks["stream_providers"]["patterns"]:
                    if re.search(pat, line_str, re.IGNORECASE):
                        checks["stream_providers"]["findings"].append((rel_path, i, line_str))
                        break

# Imprimir resultados
for key, data in checks.items():
    print(f"\n📌 {data['title']}")
    print("-" * 70)
    if not data["findings"]:
        print("  ⚠️  NO SE ENCONTRARON REFERENCIAS. (Posible punto de ruptura)")
    else:
        for path, line_no, content in data["findings"][:10]:
            print(f"  [{path}:{line_no}] {content}")
        if len(data["findings"]) > 10:
            print(f"  ... y {len(data['findings']) - 10} ocurrencias más.")

# Diagnóstico de cajas Hive
print("\n" + "=" * 70)
print("🔬 ANÁLISIS DE CONSISTENCIA EN NOMBRE DE CAJAS HIVE:")
print("-" * 70)
hive_boxes = set()
for root, _, files in os.walk(PROJECT_DIR):
    for f in files:
        if not f.endswith(".dart"):
            continue
        fp = os.path.join(root, f)
        try:
            with open(fp, "r", encoding="utf-8", errors="ignore") as file_obj:
                for line in file_obj:
                    m = re.findall(r"Hive\.box(?:<[^>]+>)?\(['\"]([^'\"]+)['\"]\)", line)
                    if m:
                        hive_boxes.update(m)
                    m2 = re.findall(r"openBox(?:<[^>]+>)?\(['\"]([^'\"]+)['\"]\)", line)
                    if m2:
                        hive_boxes.update(m2)
        except Exception:
            pass

print("Cajas detectadas en el código:", list(hive_boxes))
print("=" * 70)
print("✅ Diagnóstico completado.")
