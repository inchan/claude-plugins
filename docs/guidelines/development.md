# 개발 지침

당신은 아래 원칙을 엄격히 준수하여 코드를 설계 및 생성한다.
원칙 충돌 시, **우선순위 번호가 낮은(상위) 원칙**이 무조건 승리한다.

## 0. 의사결정 우선순위 (Priority Matrix)

| 순위 | 원칙 | 핵심 목표 | 적용 시점 (Trigger) |
| :--- | :--- | :--- | :--- |
| **P1** | **Validation First** | 검증 가능성, 명확한 성공 기준 | 코드 작성 **전** 항상 |
| **P2** | **KISS / YAGNI** | 단순성, 불필요한 복잡도 제거 | 구현 방식 선택 시 |
| **P3** | **DRY** | 의미 있는 중복 제거 | 로직이 **2곳 이상** 반복될 때 |
| **P4** | **SOLID** | 확장성, 유지보수성 | 복잡도가 임계치를 넘을 때 |

---

## 1. P1: Validation First (검증 우선)

**목표:** "작동한다"는 모호함을 배제하고, 입력/출력/예외를 명시한다.

* **[Rule 1.1] 성공 기준 선언:** 코드 생성 전, 아래 내용을 포함한 주석 또는 설명을 먼저 출력한다.
  * `Input`: 유효값 및 경계값
  * `Output`: 기대 결과
  * `Edge Cases`: `null`, `[]`, 음수 등 예외 상황 3~5개
* **[Rule 1.2] 테스트 우선:** 가능한 경우 테스트 코드를 먼저 작성(TDD)하거나, 검증 로직을 함수 상단에 배치한다.
* **[Rule 1.3] 우회 금지:** 테스트 실패 시 로직을 수정한다. Mock을 남발하여 테스트를 억지로 통과시키지 않는다.

> **Example:**
>
> ```typescript
> // ✅ Good: 성공 기준 명시
> /**
>  * sumPrices: 상품 목록의 총합 계산 (세금 제외)
>  * - Input: { price: number }[]
>  * - Edge: 빈 배열 -> 0, null -> Error Throw
>  */
> test('returns 0 for empty array', () => expect(sumPrices([])).toBe(0));
> ```

---

## 2. P2: KISS & YAGNI (단순성 유지)

**목표:** 현재 요구사항을 충족하는 가장 멍청할 정도로 단순한(Stupid Simple) 코드를 작성한다.

* **[Constraint 2.1] 정량적 복잡도 제한:**
  * **함수 길이:** 40줄 미만 (초과 시 분리)
  * **조건문 깊이(Depth):** 3단계 미만 (초과 시 `Early Return` 적용)
* **[Constraint 2.2] 미래 대비 금지:** "나중에 필요할 기능", "확장용 인터페이스", "설정 옵션" 구현 금지.
* **[Rule 2.3] 명시성:** 과도한 추상화보다 반복되는 `if`문이 낫다.

> **Example:**
>
> ```typescript
> // ❌ Bad: 미래를 대비한 과한 추상화 (YAGNI 위반)
> interface Handler { handle(req: Request): void; }
> class AbstractProcessor { /* ... */ }
>
> // ✅ Good: 현재 요구사항(상태 2개)만 처리
> function process(order: Order) {
>   if (order.isPending) return validate(order);
>   if (order.isPaid) return ship(order);
>   throw new Error('Invalid Status'); // Early Return
> }
> ```

---

## 3. P3: DRY (중복 제거)

**목표:** 로직의 중복은 제거하되, 가독성을 해치지 않는다.

* **[Rule 3.1] 3의 법칙:** 동일 로직이 **3번** 등장하기 전까지는 복사/붙여넣기를 허용한다. (섣부른 추상화 방지)
* **[Rule 3.2] 테스트 코드 예외:** 테스트 코드에서는 **DRY를 무시**한다. 각 테스트 케이스는 독립적이고(`Setup` 중복 허용), 읽기 쉬워야 한다.
* **[Rule 3.3] 매개변수 제한:** 공통 함수 추출 시 매개변수가 **5개**를 넘어가면 추출을 취소하거나 재설계한다.

> **Example:**
>
> ```typescript
> // ✅ Good (Test): 테스트 가독성을 위해 중복 허용
> test('A', () => { const order = { id: 1, items: [] }; validate(order); });
> test('B', () => { const order = { id: 2, items: [] }; ship(order); });
> ```

---

## 4. P4: SOLID (설계 원칙)

**목표:** 복잡도 통제가 불가능할 때 점진적으로 도입한다.

* **[Rule 4.1] SRP(단일 책임):** 클래스가 변경되어야 할 이유가 2가지 이상일 때 분리한다.
* **[Rule 4.2] OCP(개방 폐쇄):** `switch/if` 문이 지속적으로 늘어나는 패턴(예: 결제 수단 5개 이상)일 때만 Strategy 패턴 등을 도입한다.
* **[Guideline]** 초기 구현 단계에서 인터페이스/팩토리 패턴 도입을 **엄격히 지양**한다.

---

## 5. 실행 프로토콜 (Execution Protocol)

### 5.1 의사결정 흐름 (Decision Flow)

코드를 생성하기 전 다음 순서로 사고한다:

1. **Define Success:** 무엇이 성공인가? (테스트 케이스 정의)
2. **Check Necessity:** 지금 당장 필요한가? (미래 기능 삭제)
3. **Simplicity Check:** 더 단순하게 짤 수 없는가? (복잡도 제거)
4. **Pattern Matching:** (3번 반복 시) 중복 제거 / (복잡도 폭발 시) 디자인 패턴 적용

### 5.2 완료 조건 (Definition of Done)

출력 전 자가 점검(Self-Reflection):

* [ ] 성공 기준(입/출력)이 명시되었는가?
* [ ] 함수가 40줄/3뎁스 미만인가?
* [ ] 테스트 코드가 직관적인가? (Setup 헬퍼 등 과도한 추상화 없음)
* [ ] 실행 불가능한 '가정'이나 'Mock'이 없는가?
