from aiogram import Bot, Dispatcher, executor, types
from aiogram.contrib.fsm_storage.memory import MemoryStorage
from aiogram.dispatcher.filters.state import State, StatesGroup
from aiogram.types import ReplyKeyboardMarkup, KeyboardButton
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from aiogram.dispatcher import FSMContext
import asyncio



api = '***'
bot = Bot(token=api)
dp = Dispatcher(bot, storage=MemoryStorage())

kb1 = ReplyKeyboardMarkup(resize_keyboard=True)
button_1 = KeyboardButton(text='Рассчитать')
button_2 = KeyboardButton(text='Информация')
kb1.add(button_1, button_2)

kb2 = InlineKeyboardMarkup()
button3 = InlineKeyboardButton(text = 'Рассчитать норму калорий', callback_data='calories')
button4 = InlineKeyboardButton(text = 'Формулы расчёта', callback_data='formulas')
kb2.add(button3, button4)


class UserState(StatesGroup):
    age = State()
    growth = State()
    weight = State()

@dp.message_handler(commands=['start'])
async def start(message):
    await message.answer('Привет! Я бот помогающий твоему здоровью.', reply_markup=kb1)

@dp.message_handler(text=['Рассчитать'])
async def main_menu(message):
    await message.answer("Выберите опцию:", reply_markup = kb2)

@dp.callback_query_handler(text='formulas')
async def get_formulas(call):
    await call.message.answer("Упрощенный вариант формулы Миффлина-Сан Жеора "
                              "для мужчин: 10 х вес (кг) + 6,25 x рост (см) – 5 х возраст (г) + 5")
    await call.answer()

@dp.callback_query_handler(text = 'calories')
async def set_age(call):
    await call.message.answer("Введите свой возраст:")
    await call.answer()
    await UserState.age.set()

@dp.message_handler(state=UserState.age)
async def set_growth(message, state):
    await state.update_data(age=message.text)
    await message.answer('Введите свой рост:')
    await UserState.growth.set()

@dp.message_handler(state=UserState.growth)
async def set_weight(message, state):
    await state.update_data(growth=message.text)
    await message.answer('Введите свой вес:')
    await UserState.weight.set()

@dp.message_handler(state=UserState.weight)
async def send_calories(message, state):
    await state.update_data(weight=message.text)
    data = await state.get_data()
    calories = 10 * int(data['weight']) + 6.25 * int(data['growth']) - 5 * int(data['age']) + 5
    await message.answer(f'Ваша норма калорий -  {calories}')
    await state.finish()

@dp.message_handler()
async def all_massages(message):
    await message.answer("Введите команду /start, чтобы начать общение.")


if __name__ == "__main__":
    executor.start_polling(dp, skip_updates=True)
