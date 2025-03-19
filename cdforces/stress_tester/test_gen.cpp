#include<bits/stdc++.h>

using namespace std;

int naxTest = 20;
int naxArraySize = 50;
int naxValue = 5000;

vector<int> generateTestCase(int size, int maxValue) {
    vector<int> testCase(size);
    for (int i = 0; i < size; i++) {
        testCase[i] = rand() % maxValue + 1;
    }
    return testCase;
}

int main() {
    srand(time(0));
    int numTestCases = rand() % naxTest + 1;
    int maxArraySize = rand() % naxArraySize + 1;
    int maxValue = rand() % naxValue + 1;
    cout << numTestCases << "\n";
    for (int i = 0; i < numTestCases; i++) {
        int arraySize = rand() % maxArraySize + 1;
        // int cnt_int = rand() % naxArraySize + 1;
        cout << arraySize << "\n";
        vector<int> testCase = generateTestCase(arraySize, maxValue);
        // sort(testCase.begin(), testCase.end());
        for (int num : testCase) {
            cout << num << " ";
        }
        cout << "\n";
    }
    return 0;
}
